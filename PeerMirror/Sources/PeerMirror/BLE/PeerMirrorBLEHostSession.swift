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

    /// Token aktywnej klasy (= `QRSessionPayload.token`) — validate'owany przy pierwszym
    /// `HRSamplePayload` z każdego peer'a. Mismatch = reject (peer ze starego QR ze
    /// poprzedniej klasy, lub atak replay). Walidacja **tylko on first connect** — subsequent
    /// HR updates są trust'owane, peer już zaakceptowany w `connectedCentrals`.
    let currentSessionToken: UUID

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

    /// Aktualny obiekt `CBCentral` per `deviceID` — potrzebny do PER-DEVICE notify
    /// (`updateValue(…, onSubscribedCentrals: [central])`) przy wysyłce recap na koniec
    /// zajęć. Trzymamy sam obiekt (nie identifier), bo `onSubscribedCentrals` wymaga
    /// `CBCentral`. Aktualizowany na każdym write (central rotuje przy reconnncie).
    var centralObjects: [UUID: CBCentral] = [:]

    /// Recap notifies the BLE stack refused to queue (`updateValue` returned `false`),
    /// re-sent oldest-first from `peripheralManagerIsReady(toUpdateSubscribers:)`.
    var pendingRecapNotifies: [(data: Data, central: CBCentral)] = []

    /// Callback dla `.connected(deviceID:nick:)` i `.disconnected(deviceID:)` eventów.
    /// Wywoływane z main thread (CBPeripheralManager delegate queue = nil).
    let onPeerEvent: @Sendable (PeerEvent) -> Void

    /// Callback dla HR sample payload'ów odebranych od centralów.
    /// Wywoływane z main thread, forwarded do samplesStream w service.
    let onSample: @Sendable (HRSamplePayload) -> Void

    // MARK: - Init

    public init(
        displayName: String,
        sessionToken: UUID,
        onPeerEvent: @escaping @Sendable (PeerEvent) -> Void,
        onSample: @escaping @Sendable (HRSamplePayload) -> Void
    ) {
        self.displayName = displayName
        self.currentSessionToken = sessionToken
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
        // Wyślij "class ended" notify do wszystkich subskrybowanych peers PRZED teardown.
        // Sentinel byte 0xFF (1 byte, distinct od JSON HR payloads ~150 bytes). Peer-side
        // reagent na to żeby reset state + zniknąć z toolbar icon, NIE schodzić do .searching.
        broadcastClassEnded()

        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        for (deviceID, _) in connectedCentrals {
            onPeerEvent(.disconnected(deviceID: deviceID, reason: .hostTeardown))
        }
        connectedCentrals.removeAll()
        centralToDevice.removeAll()
        centralObjects.removeAll()
        pendingRecapNotifies.removeAll()
        Self.logger.info("Host stopped")
    }

    /// Broadcast "class ended" sentinel byte (0xFF) do wszystkich subskrybowanych centrals
    /// przez BLE notify channel na `hrCharacteristic`. Peer-side handler w
    /// `PeerMirrorBLEPeerSession+CBPeripheralDelegate.didUpdateValueFor` detect'uje sentinel
    /// (1 byte = 0xFF) i emit'uje `.classEnded` event.
    ///
    /// `onSubscribedCentrals: nil` = broadcast do wszystkich. Returns false jeśli BLE queue
    /// jest full (i wtedy `peripheralManagerIsReadyToUpdateSubscribers` byłby callback'em
    /// retry), ale dla single-byte payload + małej liczby peerów ~zawsze success.
    private func broadcastClassEnded() {
        let sentinel = Data([0xFF])
        let success = peripheralManager.updateValue(
            sentinel,
            for: hrCharacteristic,
            onSubscribedCentrals: nil
        )
        Self.logger.info("Class ended broadcast — success=\(success)")
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
        // Emit `.suspended` (NIE `.disconnected`) — service buforuje 10s grace period,
        // peer może wrócić w tym oknie i wtedy emit'ujemy `.reconnected` zamiast `.disconnected`.
        onPeerEvent(.suspended(deviceID: deviceID, nick: info.nick))
        Self.logger.info(
            "Peer suspended deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) nick=\(info.nick, privacy: .public) — entering grace period"
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

            // Graceful disconnect: peer wysłał goodbye payload (Leave tap lub workout end
            // z HK). Skip grace period — emit `.disconnected` natychmiast, usuń peer state.
            // Service patrząc na `.disconnected` cancel'uje pending grace timer (jeśli był)
            // i broadcast'uje event do reducer'a, który od razu usunie tile z UI.
            if payload.endOfClass {
                if let info = connectedCentrals.removeValue(forKey: deviceID) {
                    centralToDevice.removeValue(forKey: info.centralIdentifier)
                    centralObjects.removeValue(forKey: deviceID)
                    onPeerEvent(.disconnected(deviceID: deviceID, reason: .goodbye))
                    Self.logger.info(
                        "Peer ended class gracefully — deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) nick=\(info.nick, privacy: .public)"
                    )
                } else {
                    // Edge case: goodbye payload przyszedł od peer'a który nie był w connectedCentrals
                    // (np. host już cancel'ował go w stop()). Log + skip.
                    Self.logger.info(
                        "Goodbye from unknown peer deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) — skipping"
                    )
                }
                continue  // NIE forward'uj onSample dla goodbye (bpm=0, no real data)
            }

            // Pierwszy write z tym `deviceID` — validate token, emit `.connected` jeśli match.
            // Jeśli ten sam `deviceID` przychodzi z innego `central.identifier` (BLE radio
            // rotation po reconnect), nie emit'ujemy ponownego `.connected` ani nie
            // validate'ujemy tokenu — peer już zweryfikowany.
            if connectedCentrals[deviceID] == nil {
                guard payload.sessionToken == currentSessionToken else {
                    Self.logger.warning(
                        "Rejected peer with invalid sessionToken — deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) nick=\(payload.nick, privacy: .public) token=\(payload.sessionToken.uuidString.prefix(8), privacy: .public)"
                    )
                    // NIE forward'ujemy onSample dla odrzuconych peer'ów — żaden tile
                    // ani %HR update'ów dla nieautoryzowanego connection.
                    continue
                }
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

            // Zawsze zapamiętaj aktualny central dla tego peera — po reconnncie BLE radio
            // identifier rotuje, więc świeży write niesie aktualny obiekt do per-device notify.
            centralObjects[deviceID] = request.central

            onSample(payload)
        }
        // writeWithoutResponse nie wymaga `respond(to:withResult:)`.
    }

    /// Wysyła per-device recap (wynik zajęć) do jednego uczestnika przez `hrCharacteristic`,
    /// prefiksem `0xFE` odróżniony od HR-JSON i od `0xFF` (classEnded). Adresowany do
    /// konkretnego `CBCentral` (`onSubscribedCentrals: [central]`), więc pozostali peerzy
    /// go nie odbierają. No-op gdy peer nie ma znanego central (rozłączony/wyszedł).
    func sendRecap(_ payload: ClassRecapPayload, toDeviceID deviceID: UUID) {
        guard let central = centralObjects[deviceID] else {
            Self.logger.info("Recap skipped — no central for deviceID=\(deviceID.uuidString.prefix(8), privacy: .public)")
            return
        }
        guard let json = try? JSONEncoder().encode(payload) else { return }
        var data = Data([0xFE])
        data.append(json)
        let success = peripheralManager.updateValue(data, for: hrCharacteristic, onSubscribedCentrals: [central])
        if !success {
            // BLE queue full — park for re-send when the stack signals readiness.
            pendingRecapNotifies.append((data, central))
        }
        Self.logger.info("Recap sent to deviceID=\(deviceID.uuidString.prefix(8), privacy: .public) place=\(payload.place) success=\(success)")
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Drain recap notifies the BLE stack refused earlier. Oldest-first; stop at
        // the first refusal — the stack calls back again when it frees up.
        while let pending = pendingRecapNotifies.first {
            guard peripheralManager.updateValue(pending.data, for: hrCharacteristic, onSubscribedCentrals: [pending.central]) else { return }
            pendingRecapNotifies.removeFirst()
        }
    }
}
