//
//  HRSamplePayload.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/05/2026.
//

import Foundation

/// Payload broadcastowane z iPhone'a do iPada przez MultipeerConnectivity.
///
/// Zawiera tylko minimum potrzebne do wyświetlenia kafelka athlety —
/// nick (do display), bpm + maxHR (do obliczenia %HR), timestamp (do diagnostyki).
public struct HRSamplePayload: Codable, Sendable, Equatable {

    public let userID: UUID
    public let nick: String
    public let bpm: Int
    public let maxHR: Int
    public let timestamp: Date

    public init(
        userID: UUID,
        nick: String,
        bpm: Int,
        maxHR: Int,
        timestamp: Date = Date()
    ) {
        self.userID = userID
        self.nick = nick
        self.bpm = bpm
        self.maxHR = maxHR
        self.timestamp = timestamp
    }

    /// %HR obliczone z bpm / maxHR. Bezpieczne na maxHR = 0.
    public var percentHR: Int {
        guard maxHR > 0 else { return 0 }
        return Int((Double(bpm) / Double(maxHR)) * 100)
    }
}
