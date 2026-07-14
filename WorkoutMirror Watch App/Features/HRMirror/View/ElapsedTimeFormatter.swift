//
//  ElapsedTimeFormatter.swift
//  WorkoutMirror Watch App
//

import Foundation

/// Formats a `TimeInterval` as `MM:SS` with optional hundredths of a second.
///
/// Used with `ElapsedTimeView` and `TimelineView` to automatically drop
/// centiseconds when the display cadence is reduced (always-on mode).
final class ElapsedTimeFormatter: Formatter {

    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    /// When `true`, appends hundredths separated by the current locale's decimal separator.
    var showSubseconds: Bool = true

    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else { return nil }
        guard let formattedString = componentsFormatter.string(from: time) else { return nil }

        if showSubseconds {
            let hundredths = min(Int((time.truncatingRemainder(dividingBy: 1)) * 100), 99)
            let separator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%02d", formattedString, separator, hundredths)
        }

        return formattedString
    }
}
