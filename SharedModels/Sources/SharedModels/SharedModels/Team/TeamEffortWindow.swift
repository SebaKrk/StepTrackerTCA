//
//  TeamEffortWindow.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Heart-rate numbers limited to a plan's measurement window: from the workout start for the plan length.
public enum TeamEffortWindow {

    // Same clamp as `HeartRateZone.secondsByZone`, so coverage and zone time agree.
    private static let maxSampleGap: TimeInterval = 60

    /// Seconds per zone inside the window.
    public static func secondsByZone(
        buffer: [(date: Date, bpm: Double)],
        maxHR: Double,
        start: Date,
        minutes: Int
    ) -> [HeartRateZone: TimeInterval] {
        HeartRateZone.secondsByZone(from: samples(in: buffer, start: start, minutes: minutes), maxHR: maxHR)
    }

    /// Minutes of the window covered by samples; never scaled up, so a shorter recording simply scores less.
    public static func measuredMinutes(
        buffer: [(date: Date, bpm: Double)],
        start: Date,
        minutes: Int
    ) -> Int {
        let window = samples(in: buffer, start: start, minutes: minutes)
        let seconds = zip(window, window.dropFirst()).reduce(0.0) { total, pair in
            let gap = pair.1.date.timeIntervalSince(pair.0.date)
            return gap > 0 ? total + min(gap, maxSampleGap) : total
        }
        return Int((seconds / 60).rounded())
    }

    /// Heart rate was already in Zone 3 or above on average over the first three minutes —
    /// a hint the athlete warmed up before starting the measurement.
    public static func startedWarm(buffer: [(date: Date, bpm: Double)], maxHR: Double, start: Date) -> Bool {
        guard maxHR > 0 else { return false }
        let opening = samples(in: buffer, start: start, minutes: 3)
        guard opening.count >= 3 else { return false }
        let average = opening.reduce(0.0) { $0 + $1.bpm } / Double(opening.count)
        return average / maxHR >= warmStartFraction
    }

    // Lower bound of Zone 3 (aerobic) in `HeartRateZone`.
    private static let warmStartFraction = 0.7

    private static func samples(
        in buffer: [(date: Date, bpm: Double)],
        start: Date,
        minutes: Int
    ) -> [(date: Date, bpm: Double)] {
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        return buffer.filter { $0.date >= start && $0.date <= end }
    }
}
