//
//  AppFeatureAW+State.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import HealthKit

/// Implementation of `AppFeatureAW` state.
extension AppFeatureAW {

    @ObservableState
    struct State: Equatable {

        /// Presented when a workout session is active on the paired iPhone.
        ///
        /// Set to a new `HRMirrorFeature.State` when `.workoutStarted` arrives,
        /// cleared to `nil` when `.workoutEnded` arrives or the user taps End on Watch.
        @Presents var hrMirror: HRMirrorFeature.State?

        /// Workout configuration that arrived while the PREVIOUS session was
        /// still saving (`hrMirror.isSaving`). Creating a new `HKWorkoutSession`
        /// before `endSession()` finalizes the old one risks a HealthKit
        /// "already active" rejection, so the start is deferred until
        /// `.savedSummaryLoaded` confirms the old session is fully closed.
        var pendingActivityType: HKWorkoutActivityType?

        /// Presented on app launch when `WatchWorkoutSessionClient.checkForStuckSession()`
        /// detects an `HKWorkoutSession` left active by the previous app run (e.g. iPhone died
        /// mid-workout, Watch app was force-quit). User chooses to finalize or discard.
        @Presents var recoveryAlert: AlertState<RecoveryAlertAction>?

    }

}
