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

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        /// Delivered when the WatchConnectivity session receives a new event from iPhone.
        case watchEventReceived(WatchWorkoutEvent)

        /// Delivered when iPhone calls `HKHealthStore.startWatchApp(toHandle:)`.
        ///
        /// `WatchAppDelegate.handle(_:)` yields the activity type + location to
        /// `WorkoutConfigurationStream`, which is consumed here. This fires before
        /// WatchConnectivity `.workoutStarted` — starts `HRMirrorFeature` early so
        /// `startMirroringToCompanionDevice()` runs and watchOS brings the app to the front.
        case workoutConfigurationReceived(WorkoutConfigurationStream.Payload)

        /// Dismisses `HRMirrorFeature` after `.stop` has been sent and the
        /// `HKWorkoutSession` on Watch has finished cleaning up.
        case dismissHRMirror

        /// Delivered after `WatchWorkoutSessionClient.recoverStuckSession()` found and
        /// auto-finalized an `HKWorkoutSession` left over from the previous app run.
        /// Informational — the workout is already saved when this arrives.
        case stuckSessionRecovered(StuckSession)

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

    }

}
