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

        /// All exercises in this WOD — user edits reps/weight/sets for each.
        var exercises: [ExerciseLogInput]

        /// Index identifying which WOD this sheet edits.
        var wodIndex: Int

        /// Set to `true` when user taps Add. Parent checks this on dismiss
        /// to decide whether to write back or discard changes.
        var confirmed: Bool = false
    }
}
