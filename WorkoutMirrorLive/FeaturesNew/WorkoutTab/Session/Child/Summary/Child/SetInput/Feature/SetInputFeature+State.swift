//
//  SetInputFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension SetInputFeature {

    @ObservableState
    struct State: Equatable {

        /// WOD name displayed in the navigation title.
        var wodName: String

        /// WOD score entered by the user (e.g. "14:32", "6+14").
        var scoreText: String

        /// Placeholder for the score field based on WOD type.
        var scorePlaceholder: String

        /// All exercises in this WOD — user edits reps/weight/sets for each.
        var exercises: [ExerciseLogInput]

        /// WOD type — determines score input UI and auto-compute behavior.
        var wodType: ExerciseWorkoutType

        /// Index identifying which WOD this sheet edits.
        var wodIndex: Int

        /// Set to `true` when user taps Add. Parent checks this on dismiss
        /// to decide whether to write back or discard changes.
        var confirmed: Bool = false
    }
}
