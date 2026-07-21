//
//  PeerMirrorBLEPeerSession+CBCentralManagerDelegate.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth
import Foundation
import OSLog
import SharedModels

extension PeerMirrorBLEPeerSession: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            fileLog("central state: poweredOn")
            if !connectKnownHostIfPossible() { startScanning() }

        case .poweredOff:
            Self.logger.error("Bluetooth powered off")
            fileLog("central state: poweredOff")

        case .unauthorized:
            Self.logger.error("Bluetooth permission denied")

        case .unsupported:
            Self.logger.error("Bluetooth LE unsupported on this device")

        case .resetting:
            // Transient state — system rebuilds BLE stack. Recovery jest implicit:
            // po .resetting → .poweredOn Apple, `startScanning()` odpali się ponownie
            // z gałęzi `.poweredOn`.
            Self.logger.warning("BLE stack resetting — central will re-scan after .poweredOn")
            fileLog("central state: resetting (BLE stack rebuild)")

        case .unknown:
            Self.logger.debug("Central state .unknown (initial transient state)")

        @unknown default:
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
            fileLog("discovered RSSI=\(rssi)dBm — REJECTED (gate \(Self.rssiThreshold))")
            return
        }

        Self.logger.info(
            "Discovered peripheral RSSI=\(rssi)dBm id=\(peripheral.identifier.uuidString, privacy: .public)"
        )
        fileLog("discovered RSSI=\(rssi)dBm — connecting")

        central.stopScan()
        hostPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
        scheduleConnectTimeout(for: peripheral)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
        knownHostID = peripheral.identifier
        Self.logger.info("Connected to iPad: \(peripheral.identifier.uuidString, privacy: .public)")
        fileLog("connected — discovering services")
        resetReconnectBackoff()
        peripheral.discoverServices([BLEServiceConstants.gymRoomServiceUUID])
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
        Self.logger.error(
            "Connect failed: \(error?.localizedDescription ?? "unknown", privacy: .public)"
        )
        fileLog("connect FAILED: \(error?.localizedDescription ?? "unknown")")
        hostPeripheral = nil
        hrCharacteristic = nil
        scheduleReconnect()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Self.logger.info(
            "Disconnected: \(peripheral.identifier.uuidString, privacy: .public) error=\(error?.localizedDescription ?? "clean", privacy: .public)"
        )
        fileLog("disconnected: \(error?.localizedDescription ?? "clean")")
        onPeerEvent(.disconnected(deviceID: peripheral.identifier, reason: .connectionLost))
        hostPeripheral = nil
        hrCharacteristic = nil
        scheduleReconnect()
    }
}
