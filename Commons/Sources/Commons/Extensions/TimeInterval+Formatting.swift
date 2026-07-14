//
//  TimeInterval+Formatting.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 12/05/2026.
//

import Foundation

public extension TimeInterval {

    /// Formats duration as "1h 23m 45s" (abbreviated style).
    /// Returns "--" when formatting fails.
    func formattedDuration() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? "--"
    }

}
