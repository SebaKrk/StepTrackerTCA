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
/// Zawiera tylko minimum potrzebne do wyświetlenia kafelka athlety —
/// `deviceID` (primary key po stronie hosta), `nick` (do display), bpm + maxHR
/// (do obliczenia %HR), timestamp (do diagnostyki).
public struct HRSamplePayload: Codable, Sendable, Equatable {

    /// Stabilny identyfikator urządzenia peer'a (per-install na iPhone).
    /// Generowany raz przy pierwszym uruchomieniu, persystowany w AppStorage.
    /// Host używa go jako primary key w `connectedCentrals` — niezależny od
    /// `CBPeripheral.identifier` (Apple rotuje per BLE connection cycle).
    /// Reconnect detection: ten sam `deviceID` po disconnect/reconnect = ten sam peer.
    public let deviceID: UUID
    public let nick: String
    public let bpm: Int
    public let maxHR: Int
    public let activeEnergy: Double
    public let timestamp: Date

    public init(
        deviceID: UUID,
        nick: String,
        bpm: Int,
        maxHR: Int,
        activeEnergy: Double = 0,
        timestamp: Date = Date()
    ) {
        self.deviceID = deviceID
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
