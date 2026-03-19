//
//  ElapsedTimeFormatter.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Foundation

/// A formatter that formats elapsed time as minutes and seconds,
/// with optional display of hundredths of a second.
public class ElapsedTimeFormatter: Formatter {

    /// Formatter for minutes and seconds using DateComponentsFormatter.
    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    /// Determines whether hundredths of a second should be shown.
    public var showSubseconds = true

    /// Returns a formatted string representation of the given time interval.
    /// - Parameter value: The time interval to format.
    /// - Returns: A string with minutes and seconds, and optionally hundredths.
    public override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }

        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }

        if showSubseconds {
            let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%0.2d", formattedString, decimalSeparator, hundredths)
        }

        return formattedString
    }
    
}
