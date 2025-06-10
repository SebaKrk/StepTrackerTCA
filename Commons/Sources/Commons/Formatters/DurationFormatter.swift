//
//  DurationFormatter.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import Foundation

/// Formatter formatujący czas trwania jako godziny, minuty i sekundy.
public class DurationFormatter: Formatter {
    private let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    
    /// Returns a string representation of the given value formatted as hours, minutes, and seconds.
    /// - Parameter value: The value to format, expected to be a `TimeInterval` (seconds).
    /// - Returns: A formatted string in the "hh:mm:ss" format, or `nil` if the value cannot be formatted.
    public override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else { return nil }
        return componentsFormatter.string(from: time)
    }
}
