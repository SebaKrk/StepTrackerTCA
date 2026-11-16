//
//  ReadinessDayKey.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 09/11/2026.
//

import Foundation

/// Converts a readiness day to and from its storage key.
///
/// History is keyed by the calendar day as text (`yyyy-MM-dd`) rather than by a
/// stored instant. An instant carries a time zone offset, so the same local day
/// can land on two different keys once the user travels — two rows and two chart
/// points for one day. A calendar date cannot drift that way, and it still sorts
/// and compares correctly as text.
public enum ReadinessDayKey {

    /// Builds the storage key for a day.
    ///
    /// - Parameters:
    ///   - dayStart: Midnight of the readiness day
    ///   - calendar: Calendar used to resolve the date
    /// - Returns: The day as `yyyy-MM-dd`
    public static func key(for dayStart: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: dayStart)

        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }

    /// Rebuilds midnight of the day a key names.
    ///
    /// - Parameters:
    ///   - key: A key produced by `key(for:calendar:)`
    ///   - calendar: Calendar used to resolve the date
    /// - Returns: Midnight of that day, or `nil` when the key is malformed
    public static func dayStart(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-")

        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
