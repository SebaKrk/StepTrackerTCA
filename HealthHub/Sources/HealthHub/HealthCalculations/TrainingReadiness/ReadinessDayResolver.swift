//
//  ReadinessDayResolver.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Decides which day a readiness calculation is about, and whether it can run yet.
///
/// The day is anchored to the last time the user woke up rather than to midnight,
/// so a result stays valid until the next night — including past midnight, when
/// the training day has not actually turned over yet.
struct ReadinessDayResolver {

    // MARK: - Dependency

    @Dependency(\.sleepDataManager) var sleepDataManager
    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date

    // MARK: - Properties

    /// How far back to look for the night that anchors the day.
    private let lookback: TimeInterval = 36 * 60 * 60

    /// How stale the last night may be before the clock fallback takes over.
    ///
    /// Beyond this the Watch clearly was not worn, and carrying the old night
    /// forward would score a day against someone else's sleep.
    private let maximumSessionAge: TimeInterval = 20 * 60 * 60

    // MARK: - API

    /// Resolves the day to calculate readiness for.
    ///
    /// - Returns: The resolved day, or `nil` while the current night is still open
    /// - Throws: HealthKit errors if sleep data cannot be read
    func resolve() async throws -> ReadinessDay? {
        let now = date.now

        if let day = try await sleepAnchoredDay(now: now) {
            return day
        }

        return clockAnchoredDay(now: now)
    }

    /// Resolves a day that has already closed, for rebuilding history.
    ///
    /// Differs from `resolve()` in two ways, both because the day is in the past:
    /// it never withholds a result waiting for the night to end, and it ignores
    /// `maximumSessionAge` — an old session is precisely what it is looking for.
    ///
    /// - Parameter dayStart: Midnight of the day to resolve
    /// - Returns: The resolved day, or `nil` if its boundaries cannot be built
    /// - Throws: HealthKit errors if sleep data cannot be read
    func resolve(forDayStartingAt dayStart: Date) async throws -> ReadinessDay? {
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart),
              let searchStart = calendar.date(
                  byAdding: .second,
                  value: -Int(lookback),
                  to: dayEnd
              ) else { return nil }

        let intervals = try await sleepDataManager.getSleepIntervals(in: searchStart...dayEnd)

        if let session = SleepSessionBuilder.nightSession(
            from: intervals,
            endedBefore: dayEnd
        ), calendar.isDate(session.end, inSameDayAs: dayStart) {
            return ReadinessDay(
                dayStart: dayStart,
                nightWindow: session.start...session.end,
                anchor: .sleep(session)
            )
        }

        guard let window = TrainingReadinessTimeWindows.fallbackNightWindow(
            endingOn: dayStart,
            calendar: calendar
        ) else { return nil }

        return ReadinessDay(dayStart: dayStart, nightWindow: window, anchor: .clock)
    }

    /// When a result is expected to become available, for the waiting state.
    ///
    /// - Returns: End of the fallback night window, or `nil` if it cannot be resolved
    func expectedAvailability() -> Date? {
        let dayStart = calendar.startOfDay(for: date.now)

        return TrainingReadinessTimeWindows
            .fallbackNightWindow(endingOn: dayStart, calendar: calendar)?
            .upperBound
    }

    // MARK: - Private Methods

    /// Builds a day from the most recent night that has already ended.
    private func sleepAnchoredDay(now: Date) async throws -> ReadinessDay? {
        guard let searchStart = calendar.date(
            byAdding: .second,
            value: -Int(lookback),
            to: now
        ) else { return nil }

        let intervals = try await sleepDataManager.getSleepIntervals(in: searchStart...now)

        guard let session = SleepSessionBuilder.nightSession(
            from: intervals,
            endedBefore: now
        ) else { return nil }

        guard now.timeIntervalSince(session.end) <= maximumSessionAge else { return nil }

        return ReadinessDay(
            dayStart: calendar.startOfDay(for: session.end),
            nightWindow: session.start...session.end,
            anchor: .sleep(session)
        )
    }

    /// Builds a day from fixed clock hours, once that window has fully passed.
    private func clockAnchoredDay(now: Date) -> ReadinessDay? {
        let dayStart = calendar.startOfDay(for: now)

        guard let window = TrainingReadinessTimeWindows.fallbackNightWindow(
            endingOn: dayStart,
            calendar: calendar
        ) else { return nil }

        // Before the window closes there is nothing complete to score.
        guard now >= window.upperBound else { return nil }

        return ReadinessDay(dayStart: dayStart, nightWindow: window, anchor: .clock)
    }
}
