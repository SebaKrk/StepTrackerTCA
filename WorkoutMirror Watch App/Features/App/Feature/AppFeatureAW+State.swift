//
//  AppFeatureAW+State.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture

/// Implementation of `AppFeatureAW` state.
extension AppFeatureAW {

    @ObservableState
    struct State: Equatable {

        /// Presented when a workout session is active on the paired iPhone.
        ///
        /// Set to a new `HRMirrorFeature.State` when `.workoutStarted` arrives,
        /// cleared to `nil` when `.workoutEnded` arrives or the user taps End on Watch.
        @Presents var hrMirror: HRMirrorFeature.State?

    }

}
