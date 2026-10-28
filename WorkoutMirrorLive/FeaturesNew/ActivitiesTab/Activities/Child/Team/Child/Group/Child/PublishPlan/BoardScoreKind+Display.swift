//
//  BoardScoreKind+Display.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/10/2026.
//

import Foundation
import SharedModels

extension BoardScoreKind {

    /// What the leaderboard compares for a block of this kind: "time", "rounds + reps", "total reps", "best load".
    var displayText: String {
        switch self {
        case .time: String(localized: "time")
        case .rounds: String(localized: "rounds + reps")
        case .totalReps: String(localized: "total reps")
        case .load: String(localized: "best load")
        case .none: String(localized: "no comparable result")
        }
    }
}
