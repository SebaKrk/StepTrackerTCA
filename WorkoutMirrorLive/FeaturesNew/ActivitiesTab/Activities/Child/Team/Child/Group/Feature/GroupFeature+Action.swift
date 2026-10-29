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

        /// Internal — the member list changed.
        case membersLoaded([TeamMember])

        /// Internal — listening to members failed.
        case membersFailed

        /// Internal — the selected day's plan changed; carries whether a local copy exists.
        case dayPlanLoaded(TeamPlan?, isDownloaded: Bool)

        /// Internal — listening to the selected day's plan failed.
        case dayPlanFailed

        /// Internal — the card's download finished; `true` when the copy was saved.
        case dayPlanDownloadFinished(Bool)

        /// Internal — the user is no longer a member.
        case left

        /// Internal — leaving failed; carries the message to show.
        case leaveFailed(String)

        /// Leave confirmation and error alerts.
        case alert(PresentationAction<Alert>)

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        /// Leaderboard section.
        case leaderboard(GroupLeaderboardFeature.Action)

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

            /// Called when the user opens the selected day's plan.
            case dayPlanPreviewTapped

            /// Called when the user downloads today's plan from the card.
            case dayPlanDownloadTapped

            /// Called when the user taps the arrow to the previous day.
            case previousDayTapped

            /// Called when the user taps the arrow to the next day.
            case nextDayTapped

            /// Called when the user picks a day in the week strip.
            case daySelected(String)
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
