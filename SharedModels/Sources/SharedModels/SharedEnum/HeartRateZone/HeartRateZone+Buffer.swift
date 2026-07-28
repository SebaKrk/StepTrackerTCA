//
//  HeartRateZone+Buffer.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import Foundation

public extension HeartRateZone {

    /// Classifies a raw HR buffer into per-zone dwell time — fallback for
    /// history entries that predate persisted effort scores.
    static func secondsByZone(
        from buffer: [(date: Date, bpm: Double)],
        maxHR: Double
    ) -> [HeartRateZone: TimeInterval] {
        guard buffer.count > 1, maxHR > 0 else { return [:] }
        var result: [HeartRateZone: TimeInterval] = [:]
        for (current, next) in zip(buffer, buffer.dropFirst()) {
            // Gaps clamped to 60 s so sensor dropouts don't inflate a zone.
            let dt = min(next.date.timeIntervalSince(current.date), 60)
            guard dt > 0 else { continue }
            let zone = HeartRateZone.zone(bpm: Int(current.bpm.rounded()), maxHR: Int(maxHR))
            result[zone, default: 0] += dt
        }
        return result
    }
}
