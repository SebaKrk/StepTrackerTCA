//
//  ReadinessDay.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// The day a readiness result belongs to, anchored to when the user woke up.
///
/// Every window derived from a `ReadinessDay` ends on an event that already
/// happened — falling asleep, waking up, yesterday's midnight. That is what makes
/// the score deterministic: recalculating at 08:00, 12:00 and 23:00 returns the
/// same number, because no window reaches into the future.
public struct ReadinessDay: Sendable, Equatable {

    /// What the day is anchored to.
    public enum Anchor: Sendable, Equatable {

        /// A closed sleep session was found — the night defines the day.
        case sleep(SleepSession)

        /// No sleep was recorded, so the day falls back to a fixed clock hour.
        ///
        /// Used when the user does not wear the Watch at night. The result stays
        /// deterministic because the fallback window is only considered complete
        /// once that hour has passed.
        case clock
    }

    /// Midnight of the day this result is filed under — the history key.
    public let dayStart: Date

    /// Night window used for metrics measured during sleep, such as HRV.
    public let nightWindow: ClosedRange<Date>

    /// What defines this day: a recorded night, or the fallback clock hour.
    public let anchor: Anchor

    /// Creates a readiness day.
    ///
    /// - Parameters:
    ///   - dayStart: Midnight of the day the result is filed under
    ///   - nightWindow: Window covering the night being assessed
    ///   - anchor: Sleep session that defines the day, or the clock fallback
    public init(dayStart: Date, nightWindow: ClosedRange<Date>, anchor: Anchor) {
        self.dayStart = dayStart
        self.nightWindow = nightWindow
        self.anchor = anchor
    }

    /// The sleep session behind this day, or `nil` when anchored to the clock.
    public var sleepSession: SleepSession? {
        guard case let .sleep(session) = anchor else { return nil }
        return session
    }

    /// When the user woke up, or the end of the fallback window.
    ///
    /// Resting heart rate is written by the Watch shortly after waking, so this
    /// is the reference point its lookup window extends from.
    public var wakeTime: Date {
        nightWindow.upperBound
    }
}
