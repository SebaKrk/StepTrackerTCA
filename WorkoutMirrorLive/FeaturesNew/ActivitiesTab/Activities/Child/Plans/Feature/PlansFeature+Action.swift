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
        }
    }

}
