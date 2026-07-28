//
//  HRMinuteRange+Buffer.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 27/07/2026.
//

import Foundation

public extension HRMinuteRange {

    /// Bridges a raw HR buffer (date/bpm tuples, as collected live by the
    /// Summary screen) to per-minute ranges, reusing the `HRSample` aggregation
    /// so every screen charts identically.
    static func from(buffer: [(date: Date, bpm: Double)]) -> [HRMinuteRange] {
        let samples = buffer.map {
            HRSample(timestamp: $0.date, bpm: Int($0.bpm.rounded()), activeEnergy: 0)
        }
        return HRSample.minuteRanges(from: samples)
    }
}
