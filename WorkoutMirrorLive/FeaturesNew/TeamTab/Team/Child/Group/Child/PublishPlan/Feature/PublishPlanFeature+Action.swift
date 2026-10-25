//
//  PublishPlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension PublishPlanFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — the user's plans were loaded.
        case plansLoaded([TrainingSession])

        /// Internal — loading plans failed.
        case plansFailed

        /// Internal — the plan is live in the group.
        case published(TeamPlan)

        /// Internal — publishing failed; carries the message to show.
        case publishFailed(String)

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user picks a plan.
            case planSelected(UUID)

            /// Called when the user picks the scored block.
            case scoredBlockSelected(UUID)

            /// Called when the user asks to spread the missing minutes over the blocks.
            case fillClassLengthTapped

            /// Called when the user taps "Publish".
            case publishTapped

            /// Called when the user taps "Cancel".
            case cancelTapped
        }

        @CasePathable
        enum Delegate {

            /// Today's plan was published.
            case published(TeamPlan)
        }
    }

}
