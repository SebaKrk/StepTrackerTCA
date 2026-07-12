//
//  HRSamplePayload.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

/// Payload broadcastowane z iPhone'a do iPada przez Bluetooth Low Energy
/// (GATT characteristic write, `BLEServiceConstants.hrStreamCharacteristicUUID`).
///
/// Zawiera trzy warstwy identity (`deviceID` + `sessionToken`) + dane HR
/// (bpm + maxHR + activeEnergy) + timestamp do diagnostyki.
public struct HRSamplePayload: Codable, Sendable, Equatable {

    /// Stabilny identyfikator urządzenia peer'a (per-install na iPhone).
    /// Generowany raz przy pierwszym uruchomieniu, persystowany w AppStorage.
    /// Host używa go jako primary key w `connectedCentrals` — niezależny od
    /// `CBPeripheral.identifier` (Apple rotuje per BLE connection cycle).
    /// Reconnect detection: ten sam `deviceID` po disconnect/reconnect = ten sam peer.
    public let deviceID: UUID

    /// Token z QR code'u (`QRSessionPayload.token`) — per-class. Host validate'uje
    /// w `didReceiveWrite` przy pierwszym payload'cie: mismatch z `currentSessionToken`
    /// = peer odrzucony, kafelek się nie pojawia. Walidacja **tylko przy pierwszym**
    /// payload'cie z danym `deviceID` — subsequent updates są trust'owane (peer już
    /// zweryfikowany, nie sprawdzamy ponownie żeby uniknąć ciągłego validation overhead).
    public let sessionToken: UUID

    public let nick: String
    public let bpm: Int
    public let maxHR: Int
    public let activeEnergy: Double
    public let timestamp: Date

    /// Graceful disconnect signal — peer wysyła `true` w final payload przed disconnect
    /// (Leave button tap, lub naturalny workout end z HK). Host skip'uje grace period
    /// i emit'uje `.disconnected` natychmiast (zamiast `.suspended` + 2min grace).
    ///
    /// Default `false` — normalne HR sample updates. Tylko goodbye payload ma `true`.
    public let endOfClass: Bool

    /// Cumulative effort points (Myzone-style) computed ON THE PEER'S DEVICE —
    /// the host only displays them (single source of truth: the same number the
    /// athlete sees on their own phone). Cumulative by design: the first payload
    /// after a BLE reconnect carries the up-to-date total, so the board catches
    /// up without any repair logic. `nil` = peer build without effort points
    /// (backward compatible — optional decodes as nil when the key is absent).
    public let effortPoints: Int?

    /// `true` while the peer's BLE heart-rate strap is out of range (IOS-00100-C):
    /// `bpm` is the LAST KNOWN value, not a live reading. Payloads keep flowing as
    /// a presence keepalive, but the host must not persist these samples nor
    /// present the value as live. `nil` = legacy peer build (treat as fresh —
    /// backward compatible, optional decodes as nil when the key is absent).
    public let isSensorStale: Bool?

    public init(
        deviceID: UUID,
        sessionToken: UUID,
        nick: String,
        bpm: Int,
        maxHR: Int,
        activeEnergy: Double = 0,
        timestamp: Date = Date(),
        endOfClass: Bool = false,
        effortPoints: Int? = nil,
        isSensorStale: Bool? = nil
    ) {
        self.deviceID = deviceID
        self.sessionToken = sessionToken
        self.nick = nick
        self.bpm = bpm
        self.maxHR = maxHR
        self.activeEnergy = activeEnergy
        self.timestamp = timestamp
        self.endOfClass = endOfClass
        self.effortPoints = effortPoints
        self.isSensorStale = isSensorStale
    }

    /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
    public var percentHR: Int {
        guard maxHR > 0 else { return 0 }
        return Int((Double(bpm) / Double(maxHR)) * 100)
    }
}
