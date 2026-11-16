//
//  ExerciseWorkoutType+ScoreLabel.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation
import SharedModels

extension ExerciseWorkoutType {

    /// Caption above the score, on the card and in the editor alike.
    ///
    /// Lives in the app, not SharedModels: the package can localize, but keeping every
    /// user-facing word in one catalog beats splitting them across two.
    var scoreLabel: String {
        switch self {
        case .forTime:
            String(localized: "Score · For Time", bundle: .main)
        case .amrap:
            String(localized: "Score · AMRAP", bundle: .main)
        case .emom:
            String(localized: "Score · EMOM", bundle: .main)
        case .tabata:
            String(localized: "Score · Tabata", bundle: .main)
        case .strength, .olympicWeightlifting:
            String(localized: "Sets", bundle: .main)
        case .mobility, .intervals:
            String(localized: "Score", bundle: .main)
        }
    }
}
