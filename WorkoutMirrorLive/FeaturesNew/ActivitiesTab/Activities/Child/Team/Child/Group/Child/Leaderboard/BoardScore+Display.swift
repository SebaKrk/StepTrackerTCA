//
//  BoardScore+Display.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation
import SharedModels

extension BoardScore {

    /// Short text for a leaderboard row: "12:34", "CAP + 4", "5 rds + 12", "102.5 kg", "48 reps", "No result".
    var displayText: String {
        switch self {
        case .forTime(let seconds):
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        case .capped(_, let remainingReps):
            return String(localized: "CAP · \(remainingReps) left")
        case .cappedRounds(_, let rounds, let extraReps):
            return String(localized: "CAP · \(rounds) rds + \(extraReps)")
        case .amrap(let rounds, let extraReps):
            return String(localized: "\(rounds) rds + \(extraReps)")
        case .load(let kilograms):
            return kilograms.formatted(.number.precision(.fractionLength(0...1))) + " kg"
        case .reps(let reps):
            return String(localized: "\(reps) reps")
        case .unranked:
            return String(localized: "No result")
        }
    }
}
