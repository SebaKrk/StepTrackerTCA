//
//  AppFeatureAW+Action.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `AppFeatureAW` action.
extension AppFeatureAW {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        /// Delivered when the WatchConnectivity session receives a new event from iPhone.
        case watchEventReceived(WatchWorkoutEvent)

        /// Dismisses `HRMirrorFeature` after `.stop` has been sent and the
        /// `HKWorkoutSession` on Watch has finished cleaning up.
        case dismissHRMirror

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
