//
//  EffortPointsAccumulator.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import Foundation

/// Incremental live counter of effort points — fed one HR sample at a time
/// during an active workout (LiveSession on iPhone, HRMirror on Watch).
///
/// Accumulates SECONDS per zone and derives points on read, so the running
/// total never suffers from per-sample rounding: rounding happens once, on
/// the current aggregate — exactly like the post-workout `points(from:)` path.
public struct EffortPointsAccumulator: Equatable, Sendable {

    /// Samples further apart than this are treated as a measurement gap and
    /// NOT credited (same 5-minute rule as the HealthHub zone analyzer) —
    /// a phone left in a locker must not earn points for the missing stretch.
    public static let maxCreditedSampleGap: TimeInterval = 300

    /// Accumulated time per zone, in seconds.
    public private(set) var secondsByZone: [HeartRateZone: TimeInterval] = [:]

    public init() {}

    /// Current total — always consistent with `EffortPointsScoring.points(from:)`
    /// over the same distribution.
    public var points: Int {
        EffortPointsScoring.points(from: secondsByZone)
    }

    /// Credits `duration` seconds at the zone matching `bpm`. Ignores
    /// non-positive inputs (bpm 0 = sensor artifact, maxHR 0 = not configured)
    /// and implausible gaps (see `maxCreditedSampleGap`).
    public mutating func add(bpm: Int, duration: TimeInterval, maxHR: Int) {
        guard bpm > 0, maxHR > 0, duration > 0, duration <= Self.maxCreditedSampleGap else { return }
        let zone = HeartRateZone.zone(bpm: bpm, maxHR: maxHR)
        secondsByZone[zone, default: 0] += duration
    }

    /// Clears the counter — call on per-workout reset (new session start).
    public mutating func reset() {
        secondsByZone = [:]
    }
}
