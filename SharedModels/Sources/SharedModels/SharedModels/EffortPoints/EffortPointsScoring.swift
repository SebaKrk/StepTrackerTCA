//
//  EffortPointsScoring.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import Foundation

/// Effort points scoring policy — rewards time spent in heart rate zones
/// (Myzone-style: higher zone earns more points per minute).
///
/// Lives in SharedModels so every target computes points identically:
/// the athlete's iPhone (live counter), the Watch (mirror counter) and
/// GymRoom history (from persisted `timeInZones`). The athlete's device is
/// the single source of truth — GymRoom only displays what peers send. For a
/// GymRoom class the peer sends a WINDOW-SCOPED value (`points(from:since:)`
/// relative to the join moment), so the leaderboard is fair regardless of how
/// long the athlete trained before joining.
///
/// Persisted points are FROZEN: rebalancing the table below bumps
/// `currentWeightsVersion` for new workouts and never rewrites history.
public enum EffortPointsScoring {

    /// Version of the weights table used for a given computation — stored
    /// alongside persisted points so historical records stay attributable
    /// after a future rebalance.
    ///
    /// ⚠️ CONTRACT: ANY change to `pointsPerMinute` below MUST bump this number
    /// in the same commit. Persisted scores are frozen and never recomputed, so
    /// the only way to tell which weights produced a stored record is this
    /// version. Editing the weights without bumping it silently mislabels every
    /// new record as the old version — an unrecoverable data-integrity bug.
    public static let currentWeightsVersion = 1

    /// Points awarded per full minute in each zone (user decision 2026-07-08).
    /// Resting is absent — below Zone 1 there is no training effort to reward.
    /// Zone 5 is CAPPED at Zone 4's rate (Myzone model): reaching max effort is
    /// worth as much as threshold, but there's no bonus for lingering in the red —
    /// the scoring must not reward overtraining, matching Zone 5's own guidance
    /// ("use sparingly, long recovery"). Curve: 1·2·4·6·6 (non-decreasing).
    ///
    /// ⚠️ If you change ANY value here, bump `currentWeightsVersion` above.
    public static let pointsPerMinute: [HeartRateZone: Double] = [
        .recovery: 1,
        .fatBurning: 2,
        .aerobic: 4,
        .threshold: 6,
        .anaerobic: 6,
    ]

    /// Total points for an already-aggregated zone distribution
    /// (e.g. `ClassAnalytics.timeInZones` or a HealthKit post-workout analysis).
    /// Rounded once at the end — partial minutes score fractionally, so a
    /// 90-second stay in Zone 3 is worth 6 points, not 4 or 8.
    public static func points(from timeInZones: [HeartRateZone: TimeInterval]) -> Int {
        let total = timeInZones.reduce(0.0) { partial, entry in
            let minutes = entry.value / 60
            return partial + minutes * (pointsPerMinute[entry.key] ?? 0)
        }
        return Int(total.rounded())
    }

    /// Points earned since a baseline zone-time snapshot — for scoping a running
    /// counter to a sub-window (e.g. a GymRoom class the athlete joined mid-workout,
    /// so the leaderboard credits only effort spent in the class, not a head start
    /// from training before it began).
    ///
    /// `current` comes from `EffortPointsAccumulator`, which only ever adds, so
    /// every zone delta is >= 0. Rounds once at the end, exactly like `points(from:)`.
    public static func points(
        from current: [HeartRateZone: TimeInterval],
        since origin: [HeartRateZone: TimeInterval]
    ) -> Int {
        var delta: [HeartRateZone: TimeInterval] = [:]
        for (zone, seconds) in current {
            let diff = seconds - (origin[zone] ?? 0)
            if diff > 0 { delta[zone] = diff }
        }
        return points(from: delta)
    }

    /// Per-zone points breakdown whose values are GUARANTEED to sum to
    /// `points(from:)` for the same input. Rounding each zone independently would
    /// let the parts drift from the headline total; instead we floor each zone and
    /// hand out the leftover (`total − Σfloor`) to the zones with the largest
    /// fractional remainder (largest-remainder / Hamilton method). Use this for any
    /// per-zone display so the rows always add up to the badge.
    public static func pointsByZone(from timeInZones: [HeartRateZone: TimeInterval]) -> [HeartRateZone: Int] {
        let total = points(from: timeInZones)

        // Exact fractional points per contributing zone.
        let exact: [(zone: HeartRateZone, value: Double)] = timeInZones.compactMap { zone, seconds in
            let value = (seconds / 60) * (pointsPerMinute[zone] ?? 0)
            return value > 0 ? (zone, value) : nil
        }

        var result: [HeartRateZone: Int] = [:]
        var allocated = 0
        for entry in exact {
            let floored = Int(entry.value)
            result[entry.zone] = floored
            allocated += floored
        }

        // Distribute the rounding leftover to the largest fractional parts first.
        var leftover = total - allocated
        let byRemainder = exact.sorted {
            ($0.value - $0.value.rounded(.down)) > ($1.value - $1.value.rounded(.down))
        }
        for entry in byRemainder where leftover > 0 {
            result[entry.zone, default: 0] += 1
            leftover -= 1
        }
        return result
    }

    /// Zone for a single sample — same lookup as `ClassAnalytics` and the
    /// HealthHub zone analyzer (`percentageRange.contains`), with the same
    /// above-max fallback: a reading over 100% of maxHR counts as Zone 5.
    public static func zone(bpm: Int, maxHR: Int) -> HeartRateZone {
        let fraction = Double(bpm) / Double(maxHR)
        return HeartRateZone.allCases.first { $0.percentageRange.contains(fraction) } ?? .anaerobic
    }
}
