//
//  ReadinessFeature+State.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `ReadinessFeature` state.
extension ReadinessFeature {

    @ObservableState
    struct State: Equatable {

        /// Latest snapshot pushed from the paired iPhone; `nil` until the first one arrives.
        var snapshot: ReadinessSnapshot?

        /// Presented when the user drills into the component breakdown.
        @Presents var details: ReadinessDetailsFeature.State?
    }
}
