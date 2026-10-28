//
//  GroupFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension GroupFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — members were loaded.
        case membersLoaded([TeamMember])

        /// Internal — loading members failed.
        case membersFailed

        /// Internal — today's plan was read; carries whether a local copy exists.
        case todayPlanLoaded(TeamPlan?, isDownloaded: Bool)

        /// Internal — reading today's plan failed.
        case todayPlanFailed

        /// Internal — the card's download finished; `true` when the copy was saved.
        case todayPlanDownloadFinished(Bool)

        /// Internal — the user is no longer a member.
        case left

        /// Internal — leaving failed; carries the message to show.
        case leaveFailed(String)

        /// Leave confirmation and error alerts.
        case alert(PresentationAction<Alert>)

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user picks "Leave Group" from the menu.
            case leaveTapped

            /// Called when the user taps the QR button to invite someone.
            case inviteTapped

            /// Called when the user taps "+" to publish today's plan.
            case publishPlanTapped

            /// Called when the user opens today's plan.
            case todayPlanPreviewTapped

            /// Called when the user downloads today's plan from the card.
            case todayPlanDownloadTapped
        }

        @CasePathable
        enum Alert: Equatable {

            /// The user confirmed leaving.
            case confirmLeave
        }

        @CasePathable
        enum Delegate {

            /// The user left; the screen is closing.
            case left
        }
    }

}
