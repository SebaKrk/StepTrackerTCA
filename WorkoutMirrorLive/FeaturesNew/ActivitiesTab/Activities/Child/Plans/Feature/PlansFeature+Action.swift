//
//  PlansFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PlansFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — delivered when SQLite fetch completes.
        case sessionsLoaded([TrainingSession])

        /// Asks the list to scroll back to its top.
        case scrollToTop

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Called when view appears.
            case viewDidAppear

            /// Called when user taps "Add Plan" button.
            case addPlanTapped

            /// Called when user taps on a workout card.
            case workoutTapped(TrainingSession)

            /// Called when user taps the banner above the plans Basic does not open.
            case unlockOlderTapped

            /// Called when user taps "Import Plan".
            case importPlanTapped

            /// Reports whether the list sits away from its top.
            case scrolledChanged(Bool)
        }
    }

}
