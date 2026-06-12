//
//  PeerMirrorBLEHostSession.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 2026-05-25.
//

import CoreBluetooth
import Foundation
import OSLog
import SharedModels

/// Host role w Bluetooth Low Energy — używana przez iPad (Gym Room display).
///
/// **Responsibilities**:
/// - Publikuje custom GATT service (`gymRoomServiceUUID`) jako BLE peripheral (`CBPeripheralManager`)
/// - Eksponuje dwa characteristics: HR Stream (write + notify) + Discovery Info (read)
/// - Indexuje peer'y po `deviceID` (per-install UUID z `HRSamplePayload`) — odporne na
///   `CBPeripheral.identifier` rotation (Apple rotuje per BLE connection cycle)
/// - Odbiera HR samples przez `didReceiveWrite` i forwarduje do callbacks
///
/// **Connection model**:
/// 1. iPhone scan + connect (BLE radio level — `central.identifier` rotujący)
/// 2. iPhone subscribes do HR characteristic — peripheral loguje, ale jeszcze nie emit'uje
///    (czekamy na pierwszy payload z `deviceID` — to nasze "logical identity")
/// 3. iPhone writes pierwszy `HRSamplePayload` → emit `.connected(deviceID:, nick:)`
/// 4. iPhone unsubscribe / out of range → emit `.disconnected(deviceID:)`
///
/// **Dwie mapy**: `connectedCentrals: [UUID: PeerInfo]` keyed po `deviceID` jest primary.
/// `centralToDevice: [UUID: UUID]` to reverse lookup — `didUnsubscribeFrom` delegate dostaje
/// tylko `central.identifier`, musimy go zmapować na `deviceID` żeby znaleźć peer'a.
///
/// **Lifecycle**: stworzona w `PeerMirrorService.startAdvertising`, dropped w `stopAdvertising`.
/// Wszystkie references są `let` lub `private var` dotykane tylko z delegate callbacks
/// na main queue (`CBPeripheralManager(queue: nil)`) → safe `@unchecked Sendable`.
public final class PeerMirrorBLEHostSession: NSObject, @unchecked Sendable {

    // MARK: - Logger

    static let logger = Logger(
        subsystem: "com.ss.WorkoutMirrorLive",
        category: "BLE-Host"
    )

    // MARK: - GATT

    /// BLE Peripheral Manager — publikuje serwis jako BLE peripheral, odbiera connections/writes.
    let peripheralManager: CBPeripheralManager

    /// HR Stream characteristic — writeWithoutResponse (data transport) + notify (presence detection).
    /// Notify nie wysyła danych — tylko sygnalizuje subscribe/unsubscribe dla connection tracking.
    let hrCharacteristic: CBMutableCharacteristic

    /// Discovery Info characteristic — read-only, zawiera displayName iPada jako UTF8 data.
    /// Umożliwia iPhone'm pobranie nazwy sali zamiast cryptic UUID.
    let discoveryInfoCharacteristic: CBMutableCharacteristic

    /// GATT Service — zawiera oba characteristics, publikowany przez peripheralManager.
    let service: CBMutableService

    // MARK: - State

    /// Display name iPada — publikowany w Discovery Info characteristic oraz advertisement data.
    let displayName: String

    /// Info o połączonym peerze — trzymane razem zamiast kilku map, żeby uniknąć desync'u.
    struct PeerInfo: Sendable {
        /// BLE radio identifier — może rotować przy kolejnym connection cycle (Apple privacy).
        let centralIdentifier: UUID
        /// Stabilny per-install identifier peer'a — primary key.
        let deviceID: UUID
        /// Display name.
        let nick: String
    }

    /// Aktualnie połączeni peer'y, keyed po `deviceID` (primary key).
    /// Pierwszy `HRSamplePayload` z danym `deviceID` emit'uje `.connected`,
    /// usunięcie wpisu (przez `didUnsubscribeFrom` lub `stop()`) emit'uje `.disconnected`.
    var connectedCentrals: [UUID: PeerInfo] = [:]

    /// Reverse lookup `central.identifier` → `deviceID`. Potrzebny w `didUnsubscribeFrom`,
    /// gdzie BLE delegate daje tylko `CBCentral.identifier`, a my musimy znaleźć
    /// `deviceID` żeby usunąć właściwy wpis z `connectedCentrals` i emit `.disconnected`.
    var centralToDevice: [UUID: UUID] = [:]

    /// Callback dla `.connected(deviceID:nick:)` i `.disconnected(deviceID:)` eventów.
    /// Wywoływane z main thread (CBPeripheralManager delegate queue = nil).
    let onPeerEvent: @Sendable (PeerEvent) -> Void

    /// Callback dla HR sample payload'ów odebranych od centralów.
    /// Wywoływane z main thread, forwarded do samplesStream w service.
    let onSample: @Sendable (HRSamplePayload) -> Void

    // MARK: - Init

    public init(
        displayName: String,
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void,
        onSample: @escaping @Sendable (HRSamplePayload) -> Void
    ) {
        self.displayName = displayName
        self.onPeerEvent = onPeerEvent
        self.onSample = onSample

        // HR Stream: writeWithoutResponse (data path) + notify (presence path).
        // Notify nie służy do wysyłania danych — tylko do detection subscribe/unsubscribe.
        self.hrCharacteristic = CBMutableCharacteristic(
            type: BLEServiceConstants.hrStreamCharacteristicUUID,
            properties: [.writeWithoutResponse, .notify],
            value: nil,
            permissions: [.writeable]
        )

        // Discovery Info: read-only z cached value. PoC: UTF8(displayName).
        // Future: JSON `{roomName, sessionId, capacity}` (IPAD-0096+).
        let infoPayload = Data(displayName.utf8)
        self.discoveryInfoCharacteristic = CBMutableCharacteristic(
            type: BLEServiceConstants.discoveryInfoCharacteristicUUID,
            properties: [.read],
            value: infoPayload,
            permissions: [.readable]
        )

        let gattService = CBMutableService(
            type: BLEServiceConstants.gymRoomServiceUUID,
            primary: true
        )
        gattService.characteristics = [hrCharacteristic, discoveryInfoCharacteristic]
        self.service = gattService

        // queue: nil → main queue. Wszystkie callbacks main-thread.
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
        super.init()
        self.peripheralManager.delegate = self
    }

    // MARK: - Public

    public func stop() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        for (deviceID, _) in connectedCentrals {
            onPeerEvent(.disconnected(deviceID: deviceID))
        }
        connectedCentrals.removeAll()
        centralToDevice.removeAll()
        Self.logger.info("Host stopped")
    }
}

// MARK: - CBPeripheralManagerDelegate

extension PeerMirrorBLEHostSession: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            peripheral.add(service)
            let advertisementData: [String: Any] = [
                CBAdvertisementDataServiceUUIDsKey: [BLEServiceConstants.gymRoomServiceUUID],
                CBAdvertisementDataLocalNameKey: displayName
            ]
            peripheral.startAdvertising(advertisementData)
            Self.logger.info("Advertising started as \(self.displayName, privacy: .public)")

        case .poweredOff:
            Self.logger.error("Bluetooth powered off")

        case .unauthorized:
            Self.logger.error("Bluetooth permission denied")

        case .unsupported:
            Self.logger.error("Bluetooth LE unsupported on this device")

        case .resetting:
            // Transient state — system rebuilds BLE stack. Recovery jest implicit:
            // po .resetting → .poweredOn Apple, `peripheral.add(service)` + `startAdvertising`
            // odpalą się ponownie z gałęzi `.poweredOn`.
            Self.logger.warning("BLE stack resetting — peripheral connections will re-establish after .poweredOn")

        case .unknown:
            Self.logger.debug("Peripheral state .unknown (initial transient state)")

        @unknown default:
            Self.logger.debug("Peripheral state: \(peripheral.state.rawValue)")
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?
    ) {
        if let error {
            Self.logger.error("Failed to add service: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == BLEServiceConstants.hrStreamCharacteristicUUID else { return }
        // No-op emit: czekamy na pierwszy `HRSamplePayload` z `deviceID` żeby zaindexować
        // peer'a po stabilnym identifierze (subscribe sam daje tylko BLE-level `central.identifier`).
        // Tile w UI pojawi się przy pierwszym sample (latency typowo <2s).
        Self.logger.info("Central subscribed: \(central.identifier.uuidString, privacy: .public)")
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == BLEServiceConstants.hrStreamCharacteristicUUID else { return }
        let identifier = central.identifier
        // Delegate daje nam tylko BLE-level `central.identifier` — używamy reverse lookup
        // żeby znaleźć `deviceID` i wyciągnąć właściwy wpis z `connectedCentrals`.
        guard let deviceID = centralToDevice.removeValue(forKey: identifier),
              let info = connectedCentrals.removeValue(forKey: deviceID) else {
            // Subscribe bez żadnego write — nic nie emit'owaliśmy, nie ma czego cofać.
            Self.logger.info("Central unsubscribed without registered deviceID: \(identifier.uuidString, privacy: .public)")
            return
        }
        onPeerEvent(.disconnected(deviceID: deviceID))
        Self.logger.info(
            "Peer disconnected deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) nick=\(info.nick, privacy: .public)"
        )
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            guard request.characteristic.uuid == BLEServiceConstants.hrStreamCharacteristicUUID,
                  let data = request.value,
                  let payload = try? JSONDecoder().decode(HRSamplePayload.self, from: data)
            else {
                continue
            }

            let identifier = request.central.identifier
            let deviceID = payload.deviceID
            // Pierwszy write z tym `deviceID` — emit `.connected`.
            // Jeśli ten sam `deviceID` przychodzi z innego `central.identifier`
            // (BLE radio rotation po reconnect), aktualizujemy mapping ale NIE emit'ujemy
            // ponownego `.connected` — to ten sam peer.
            if connectedCentrals[deviceID] == nil {
                let info = PeerInfo(
                    centralIdentifier: identifier,
                    deviceID: deviceID,
                    nick: payload.nick
                )
                connectedCentrals[deviceID] = info
                centralToDevice[identifier] = deviceID
                onPeerEvent(.connected(deviceID: deviceID, nick: payload.nick))
                Self.logger.info(
                    "Peer registered deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) nick=\(payload.nick, privacy: .public) central=\(identifier.uuidString, privacy: .public)"
                )
            }

            onSample(payload)
        }
        // writeWithoutResponse nie wymaga `respond(to:withResult:)`.
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // No-op: peripheral nie wysyła notify update'ów (notify służy tylko do presence detection).
    }
}
