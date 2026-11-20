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
    /// Resting heart rate is a per-day aggregate the Watch stamps with the start
    /// of the day it describes, not a moment measured during the night, so the
    /// window is a whole calendar day rather than a slice around waking.
    ///
    /// It stops at the readiness day's own midnight on purpose: today's sample
    /// does not exist until the Watch has processed today, and letting it appear
    /// part-way through the day would move a score already on screen.
    ///
    /// - Parameters:
    ///   - day: The readiness day being calculated
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Range covering the day before the readiness day
    static func restingHeartRateWindow(
        for day: ReadinessDay,
        calendar: Calendar = .current
    ) -> ClosedRange<Date> {
        guard let start = calendar.date(byAdding: .day, value: -1, to: day.dayStart) else {
            return day.dayStart...day.dayStart
        }

        return start...day.dayStart.addingTimeInterval(-1)
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

    /// Returns one range per preceding calendar day.
    ///
    /// Used for every signal the system aggregates per day — resting heart rate
    /// and activity load — so both are measured the same way.
    ///
    /// - Parameters:
    ///   - count: How many days to cover
    ///   - day: The readiness day being calculated
    ///   - skipped: How many days to leave out directly before the readiness day
    ///   - calendar: Calendar used to resolve day boundaries
    /// - Returns: Ranges ordered from most recent to oldest
    ///
    /// - Note: Pass `skipping: 1` for a baseline whose measured value is already
    ///   yesterday's aggregate — otherwise the day being scored sits inside the
    ///   baseline it is compared against and dilutes its own deviation.
    static func previousDays(
        count: Int,
        before day: ReadinessDay,
        skipping skipped: Int = 0,
        calendar: Calendar = .current
    ) -> [ClosedRange<Date>] {
        let first = max(skipped, 0) + 1
        let last = first + max(count, 1) - 1

        return (first...last).compactMap { dayOffset in
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

        // Set on the previous day rather than subtracted as absolute hours: on a
        // daylight-saving night the subtraction yields 21:00 or 19:00 and makes
        // one night of the baseline pool span an hour more or less than the rest.
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart),
              let start = calendar.date(
                  bySettingHour: fallbackSleepHour,
                  minute: 0,
                  second: 0,
                  of: previousDay
              ) else {
            return nil
        }

        return start...end
    }
}
