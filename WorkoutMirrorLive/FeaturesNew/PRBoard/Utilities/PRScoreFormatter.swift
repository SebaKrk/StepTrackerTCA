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
        switch score {
        case let .weight(kilograms):
            return "\(weightString(kilograms)) kg"
        case let .time(seconds):
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        case let .reps(count):
            return "\(count) \(String(localized: "reps"))"
        case let .amrap(rounds, extraReps):
            return "\(rounds)+\(extraReps)"
        }
    }

    /// Whole kilograms render without the decimal ("150", not "150.0").
    private static func weightString(_ kilograms: Double) -> String {
        kilograms.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", kilograms)
            : String(format: "%.1f", kilograms)
    }
}
