//
//  PeerMirrorBLEPeerSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth
import Foundation
import OSLog
import SharedModels

/// Peer role w Bluetooth Low Energy — używana przez iPhone (athlete dołączający do klasy).
///
/// **Responsibilities**:
/// - Scanuje broadcast iPada (`CBCentralManager.scanForPeripherals(withServices:)`)
/// - Proximity gate przez RSSI (`> -75 dBm` ~10m)
/// - Connect + discover services + characteristics
/// - Subscribe do HR Stream characteristic (presence signaling do peripheral)
/// - Wysyła `HRSamplePayload` przez `writeValue(_, for:, type: .withoutResponse)`
/// - Auto-reconnect z exponential backoff (1s → 2s → 4s → 8s → cap 30s)
///
/// **Lifecycle**: stworzona w `PeerMirrorService.startBrowsing`, dropped w `stopBrowsing`.
public final class PeerMirrorBLEPeerSession: NSObject, @unchecked Sendable {

    // MARK: - Logger

    private static let logger = Logger(
        subsystem: "com.ss.WorkoutMirrorLive",
        category: "BLE-Peer"
    )

    /// RSSI threshold dla proximity gate. -75 dBm ≈ 10m (typowy zasięg sali).
    /// Słabszy signal = user nie w sali, ignorujemy advertisement.
    private static let rssiThreshold: Int = -75

    /// Max delay przed kolejnym reconnect attempt (po `lostPeripheralResetTimeoutSeconds`).
    private static let maxReconnectDelaySeconds: TimeInterval = 30

    // MARK: - BLE

    private let centralManager: CBCentralManager
    private var hostPeripheral: CBPeripheral?
    private var hrCharacteristic: CBCharacteristic?

    // MARK: - Reconnect state

    private var reconnectDelaySeconds: TimeInterval = 1
    private var shouldAutoReconnect = true

    // MARK: - Callbacks

    private let onPeerEvent: @Sendable (PeerEvent) -> Void

    // MARK: - Init

    public init(
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void
    ) {
        self.onPeerEvent = onPeerEvent
        self.centralManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        self.centralManager.delegate = self
    }

    // MARK: - Public

    public func stop() {
        shouldAutoReconnect = false
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        if let peripheral = hostPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        hostPeripheral = nil
        hrCharacteristic = nil
        Self.logger.info("Peer stopped")
    }

    public func send(_ payload: HRSamplePayload) {
        guard let peripheral = hostPeripheral,
              let characteristic = hrCharacteristic,
              peripheral.state == .connected
        else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            // writeWithoutResponse: idempotent stream, brak ACK overhead, zgubiony sample OK.
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } catch {
            Self.logger.error("Encode failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private (scan/reconnect)

    private func startScanning() {
        guard centralManager.state == .poweredOn, !centralManager.isScanning else { return }
        centralManager.scanForPeripherals(
            withServices: [BLEServiceConstants.gymRoomServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        Self.logger.info("Scanning started")
    }

    private func scheduleReconnect() {
        guard shouldAutoReconnect else { return }
        let delay = reconnectDelaySeconds
        reconnectDelaySeconds = min(reconnectDelaySeconds * 2, Self.maxReconnectDelaySeconds)
        Self.logger.info("Reconnect scheduled in \(delay, format: .fixed(precision: 1))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startScanning()
        }
    }

    private func resetReconnectBackoff() {
        reconnectDelaySeconds = 1
    }
}

// MARK: - CBCentralManagerDelegate

extension PeerMirrorBLEPeerSession: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()

        case .poweredOff:
            Self.logger.error("Bluetooth powered off")

        case .unauthorized:
            Self.logger.error("Bluetooth permission denied")

        case .unsupported:
            Self.logger.error("Bluetooth LE unsupported on this device")

        default:
            Self.logger.debug("Central state: \(central.state.rawValue)")
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssi = RSSI.intValue
        guard rssi >= Self.rssiThreshold else {
            // Słaby signal — user prawdopodobnie nie w sali. Ignorujemy.
            return
        }

        Self.logger.info(
            "Discovered peripheral RSSI=\(rssi)dBm id=\(peripheral.identifier.uuidString, privacy: .public)"
        )

        central.stopScan()
        hostPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Self.logger.info("Connected to iPad: \(peripheral.identifier.uuidString, privacy: .public)")
        resetReconnectBackoff()
        peripheral.discoverServices([BLEServiceConstants.gymRoomServiceUUID])
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Self.logger.error(
            "Connect failed: \(error?.localizedDescription ?? "unknown", privacy: .public)"
        )
        hostPeripheral = nil
        hrCharacteristic = nil
        scheduleReconnect()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let peripheralID = peripheral.identifier.uuidString
        Self.logger.info(
            "Disconnected: \(peripheralID, privacy: .public) error=\(error?.localizedDescription ?? "clean", privacy: .public)"
        )
        onPeerEvent(.disconnected(peerID: peripheralID))
        hostPeripheral = nil
        hrCharacteristic = nil
        scheduleReconnect()
    }
}

// MARK: - CBPeripheralDelegate

extension PeerMirrorBLEPeerSession: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            Self.logger.error("Service discovery failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard let gymService = peripheral.services?.first(
            where: { $0.uuid == BLEServiceConstants.gymRoomServiceUUID }
        ) else {
            Self.logger.error("GymRoom service not found on peripheral")
            return
        }
        peripheral.discoverCharacteristics(
            [BLEServiceConstants.hrStreamCharacteristicUUID,
             BLEServiceConstants.discoveryInfoCharacteristicUUID],
            for: gymService
        )
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            Self.logger.error(
                "Characteristic discovery failed: \(error.localizedDescription, privacy: .public)"
            )
            return
        }
        guard let hr = service.characteristics?.first(
            where: { $0.uuid == BLEServiceConstants.hrStreamCharacteristicUUID }
        ) else {
            Self.logger.error("HR characteristic not found")
            return
        }
        hrCharacteristic = hr

        // Subscribe (presence signaling do peripheral via `didSubscribeTo` callback).
        // Peripheral nie wysyła żadnych notify update'ów — to tylko keep-alive marker.
        peripheral.setNotifyValue(true, for: hr)

        onPeerEvent(.connected(peerID: peripheral.identifier.uuidString, nick: ""))
        Self.logger.info("Subscribed to HR characteristic — ready to send")
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            Self.logger.error(
                "Notify state error: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
