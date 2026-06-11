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

    public init(
        deviceID: UUID,
        sessionToken: UUID,
        nick: String,
        bpm: Int,
        maxHR: Int,
        activeEnergy: Double = 0,
        timestamp: Date = Date()
    ) {
        self.deviceID = deviceID
        self.sessionToken = sessionToken
        self.nick = nick
        self.bpm = bpm
        self.maxHR = maxHR
        self.activeEnergy = activeEnergy
        self.timestamp = timestamp
    }

    /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
    public var percentHR: Int {
        guard maxHR > 0 else { return 0 }
        return Int((Double(bpm) / Double(maxHR)) * 100)
    }
}
