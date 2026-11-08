//
//  TrainingReadinessTimeWindows.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 30/09/2025.
//

import Foundation
import SharedModels

/// Builds the time ranges a readiness calculation queries HealthKit with.
///
/// ## Design Rationale
/// Every window is derived from a `ReadinessDay`, never from the current time.
/// That is the invariant the whole feature rests on: no window may end in the
/// future, because HealthKit would answer with a partial reading and the score
/// would depend on when the app was opened rather than on how the user slept.
///
/// ## Usage
/// ```swift
/// let window = TrainingReadinessTimeWindows.restingHeartRateWindow(for: day)
/// let samples = try await fetchRHR(from: window.lowerBound, to: window.upperBound)
/// ```
struct TrainingReadinessTimeWindows {

    /// How long after waking the Watch may still write the day's resting heart rate.
    private static let restingHeartRateGrace: TimeInterval = 2 * 60 * 60

    /// Hour the fallback night window ends at when no sleep was recorded.
    static let fallbackWakeHour = 10

    /// Hour the fallback night window starts at on the previous evening.
    ///
    /// Deliberately early: a window that starts too late silently drops sleep
    /// that began in the evening, which would under-report the night.
    static let fallbackSleepHour = 20

    /// Returns the window covering the night being assessed.
    ///
    /// Heart rate variability is only meaningful when measured at rest, so it is
    /// read from exactly this range.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: Range from falling asleep to waking up
    static func nightWindow(for day: ReadinessDay) -> ClosedRange<Date> {
        day.nightWindow
    }

    /// Returns the window a resting heart rate reading is accepted from.
    ///
    /// Extends past waking because the Watch writes the daily resting heart rate
    /// once it has processed the night, not at the moment of waking.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: Range from falling asleep to shortly after waking
    static func restingHeartRateWindow(for day: ReadinessDay) -> ClosedRange<Date> {
        day.nightWindow.lowerBound...day.wakeTime.addingTimeInterval(restingHeartRateGrace)
    }

    /// Returns the full calendar day preceding the readiness day.
    ///
    /// Yesterday's training load is what the body is recovering from.
    ///
    /// - Parameters:
    ///   - day: The readiness day being calculated
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Range covering the previous day, or `nil` if it cannot be resolved
    static func previousDay(
        for day: ReadinessDay,
        calendar: Calendar = .current
    ) -> ClosedRange<Date>? {
        guard let start = calendar.date(byAdding: .day, value: -1, to: day.dayStart),
              let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return nil
        }
        return start...end.addingTimeInterval(-1)
    }

    /// Returns one range per preceding calendar day, used for activity baselines.
    ///
    /// Starts at one day back: the day being scored must never be part of the
    /// baseline it is compared against.
    ///
    /// - Parameters:
    ///   - count: How many preceding days to cover
    ///   - day: The readiness day being calculated
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Ranges ordered from most recent to oldest
    static func previousDays(
        count: Int,
        before day: ReadinessDay,
        calendar: Calendar = .current
    ) -> [ClosedRange<Date>] {
        (1...max(count, 1)).compactMap { dayOffset in
            guard let start = calendar.date(byAdding: .day, value: -dayOffset, to: day.dayStart),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                return nil
            }
            return start...end.addingTimeInterval(-1)
        }
    }

    /// Returns one night window per preceding day, used for sleep and HRV baselines.
    ///
    /// Each window mirrors the shape of the fallback night so every day in the
    /// baseline is measured the same way. Starts at one day back for the same
    /// reason as `previousDays(count:before:)`.
    ///
    /// - Parameters:
    ///   - count: How many preceding nights to cover
    ///   - day: The readiness day being calculated
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Ranges ordered from most recent to oldest
    static func previousNights(
        count: Int,
        before day: ReadinessDay,
        calendar: Calendar = .current
    ) -> [ClosedRange<Date>] {
        (1...max(count, 1)).compactMap { dayOffset in
            guard let reference = calendar.date(byAdding: .day, value: -dayOffset, to: day.dayStart) else {
                return nil
            }
            return fallbackNightWindow(endingOn: reference, calendar: calendar)
        }
    }

    /// Returns one resting heart rate window per preceding day.
    ///
    /// Mirrors `restingHeartRateWindow(for:)` so the baseline is measured the same
    /// way as the value compared against it.
    ///
    /// - Parameters:
    ///   - count: How many preceding days to cover
    ///   - day: The readiness day being calculated
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Ranges ordered from most recent to oldest
    static func previousRestingHeartRateWindows(
        count: Int,
        before day: ReadinessDay,
        calendar: Calendar = .current
    ) -> [ClosedRange<Date>] {
        previousNights(count: count, before: day, calendar: calendar).map { night in
            night.lowerBound...night.upperBound.addingTimeInterval(restingHeartRateGrace)
        }
    }

    /// Returns the clock-based night window for a day with no recorded sleep.
    ///
    /// - Parameters:
    ///   - dayStart: Midnight of the day the window belongs to
    ///   - calendar: Calendar used to resolve hour boundaries
    /// - Returns: Range from the previous evening to the fallback wake hour
    static func fallbackNightWindow(
        endingOn dayStart: Date,
        calendar: Calendar = .current
    ) -> ClosedRange<Date>? {
        guard let end = calendar.date(
            bySettingHour: fallbackWakeHour,
            minute: 0,
            second: 0,
            of: dayStart
        ) else { return nil }

        let hoursBack = (24 - fallbackSleepHour) + fallbackWakeHour

        guard let start = calendar.date(byAdding: .hour, value: -hoursBack, to: end) else {
            return nil
        }

        return start...end
    }
}
