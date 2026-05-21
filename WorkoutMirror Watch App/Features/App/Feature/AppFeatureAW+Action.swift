//
//  AppFeatureAW+Action.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import HealthKit
import SharedModels

/// Implementation of `AppFeatureAW` action.
extension AppFeatureAW {

    /// Recovery alert button actions — used by `AlertState<RecoveryAlertAction>`.
    enum RecoveryAlertAction: Equatable {
        /// User tapped "Zakończ teraz" — finalize the recovered session and save the `HKWorkout`.
        case endTapped

        /// User tapped "Odrzuć" — discard the recovered session without saving.
        case discardTapped
    }

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        /// Delivered when the WatchConnectivity session receives a new event from iPhone.
        case watchEventReceived(WatchWorkoutEvent)

        /// Delivered when iPhone calls `HKHealthStore.startWatchApp(toHandle:)`.
        ///
        /// `WatchAppDelegate.handle(_:)` yields the activity type to
        /// `WorkoutConfigurationStream`, which is consumed here. This fires before
        /// WatchConnectivity `.workoutStarted` — starts `HRMirrorFeature` early so
        /// `startMirroringToCompanionDevice()` runs and watchOS brings the app to the front.
        case workoutConfigurationReceived(HKWorkoutActivityType)

        /// Dismisses `HRMirrorFeature` after `.stop` has been sent and the
        /// `HKWorkoutSession` on Watch has finished cleaning up.
        case dismissHRMirror

        /// Delivered when `WatchWorkoutSessionClient.checkForStuckSession()` finds an active
        /// `HKWorkoutSession` left over from the previous app run. Triggers `recoveryAlert`.
        case stuckSessionDetected(StuckSession)

        // MARK: - View Actions

        case view(ViewAction)

        enum ViewAction {

            /// Called when `AppViewAW` appears on screen.
            ///
            /// Starts listening on the `incomingEventStream` from the paired iPhone.
            case onAppear

        }
        
        // MARK: - Child Actions

        /// Delegates to `HRMirrorFeature` child reducer.
        case hrMirror(PresentationAction<HRMirrorFeature.Action>)

        /// Delegates to the recovery alert presentation lifecycle.
        case recoveryAlert(PresentationAction<RecoveryAlertAction>)

    }

}
