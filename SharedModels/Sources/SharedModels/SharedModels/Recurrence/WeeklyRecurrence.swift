//
//  WeeklyRecurrence.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import Foundation

/// Weekly-recurrence date math for GymRoom classes.
///
/// A recurring class stores a single base date (its first occurrence, e.g.
/// Wed 15.07 19:30). The list must show the NEXT occurrence — the same weekday
/// and time, rolled forward in 7-day steps until it is no longer in the past.
/// No separate records are generated; the displayed date is always computed.
public enum WeeklyRecurrence {

    /// The next occurrence of `base` that is not before `now`, stepping by whole
    /// weeks so the weekday and wall-clock time are preserved across DST.
    ///
    /// - If `base` is still in the future, it is returned unchanged (the first
    ///   occurrence hasn't happened yet).
    /// - Otherwise it advances week by week via `Calendar` (not raw 7×24h, which
    ///   would drift the local time across a daylight-saving change).
    ///
    /// `now` is injected (not read from the clock) so callers stay testable.
    public static func nextOccurrence(
        of base: Date,
        notBefore now: Date,
        calendar: Calendar = .current
    ) -> Date {
        guard base < now else { return base }

        // Jump most of the way in one `Calendar` step, then correct — cheaper than
        // looping week by week over a long gap, and still DST-correct.
        let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60
        let approxWeeks = Int(now.timeIntervalSince(base) / secondsPerWeek)
        var candidate = calendar.date(byAdding: .weekOfYear, value: approxWeeks, to: base) ?? base

        while candidate < now {
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: candidate) else { break }
            candidate = next
        }
        return candidate
    }
}
