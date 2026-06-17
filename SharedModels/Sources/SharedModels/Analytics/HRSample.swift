//
//  HRSample.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 17/06/2026.
//

import Foundation

/// Pojedyncza próbka HR sportowca w klasie treningowej.
///
/// **Producer**: iPhone peer'a wysyła `HRSamplePayload` po BLE @ 1Hz. iPad host
/// extract'uje `bpm` + `activeEnergy` + timestamp odbioru → `HRSample`.
///
/// **Storage**: kolekcja `[HRSample]` per athlete jest JSON-encoded do BLOB
/// (`AthleteSessionRecord.hrSamplesData`) — flat array, sortowany rosnąco po timestamp.
///
/// **Aggregation**: `[HRSample]` → `ClassAnalytics` (avg, peak, totalCalories, zones)
/// computed na `peerDisconnected` / class end.
public struct HRSample: Codable, Sendable, Equatable {

    /// Czas odbioru sample'a po stronie host'a (iPad). Source of truth dla chronologii
    /// w line chart HR over time.
    public let timestamp: Date

    /// Heart rate w beats per minute. Range [0...250] w praktyce.
    public let bpm: Int

    /// Active energy spalony od poprzedniego sample'a (kcal cumulative ze strony peer'a).
    public let activeEnergy: Double

    public init(timestamp: Date, bpm: Int, activeEnergy: Double) {
        self.timestamp = timestamp
        self.bpm = bpm
        self.activeEnergy = activeEnergy
    }
}
