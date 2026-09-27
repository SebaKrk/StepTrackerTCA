//
//  ReadinessFeature+Action.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `ReadinessFeature` action.
extension ReadinessFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Internal Actions

        /// Delivered when the paired iPhone pushes a new readiness snapshot
        /// through the WatchConnectivity application context.
        case snapshotReceived(ReadinessSnapshot)

        // MARK: - View Actions

        case view(ViewAction)

        @CasePathable
        enum ViewAction {

            /// Called when `ReadinessView` appears on screen.
            ///
            /// Seeds state from the context `WCSession` already holds, then starts
            /// listening for subsequent pushes.
            case onAppear

            /// Called when the user taps the score to inspect the component breakdown.
            case scoreTapped

        }

        // MARK: - Child Actions

        /// Delegates to `ReadinessDetailsFeature` child reducer.
        case details(PresentationAction<ReadinessDetailsFeature.Action>)

    }

}
