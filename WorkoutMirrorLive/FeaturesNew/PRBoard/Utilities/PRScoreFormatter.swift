//
//  PRScoreFormatter.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation
import SharedModels

/// Shared display formatting of PR score values (list rows, detail hero, history).
enum PRScoreFormatter {

    /// "150 kg" / "152.5 kg" / "6:30" / "21 reps" / "6+7".
    static func string(for score: PRScoreValue) -> String {
        let (value, unit) = parts(for: score)
        guard let unit else { return value }
        return "\(value) \(unit)"
    }

    /// Score split for the hero card: big value + smaller unit
    /// ("150"+"kg", "6:30"+nil, "21"+"reps", "6+7"+"rounds").
    static func parts(for score: PRScoreValue) -> (value: String, unit: String?) {
        switch score {
        case let .weight(kilograms):
            return (weightString(kilograms), "kg")
        case let .time(seconds):
            return (String(format: "%d:%02d", seconds / 60, seconds % 60), nil)
        case let .reps(count):
            return ("\(count)", String(localized: "reps"))
        case let .amrap(rounds, extraReps):
            return ("\(rounds)+\(extraReps)", String(localized: "rounds"))
        }
    }

    /// Whole kilograms render without the decimal ("150", not "150.0").
    private static func weightString(_ kilograms: Double) -> String {
        kilograms.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", kilograms)
            : String(format: "%.1f", kilograms)
    }
}
