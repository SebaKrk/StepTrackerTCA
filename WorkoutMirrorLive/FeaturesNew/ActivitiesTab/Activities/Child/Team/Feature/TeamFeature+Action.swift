//
//  TeamFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension TeamFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — signed in; carries the account id and the name shown to others.
        case signedIn(uid: String, displayName: String)

        /// Internal — the live list of groups changed.
        case groupsUpdated([TeamGroup])

        /// Internal — sign-in or the groups listener failed.
        case groupsFailed

        /// Internal — the scanned invites changed; carries the clock for their status.
        case invitationsUpdated([TeamInvitation], now: Date)

        /// Internal — join or decline of an invitation finished (successfully or not).
        case invitationResponseFinished(TeamInvitation.ID)

        /// Internal — the user's results for today's plans arrived, by group id.
        case myEntriesLoaded([String: TeamEntry])

        /// Decline confirmation.
        case alert(PresentationAction<Alert>)

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user switches between Private and Public.
            case segmentChanged(TeamSegment)

            /// Called when the user taps "Try again" after a failure.
            case retryTapped

            /// Called on pull to refresh; the effect ends when the groups are re-read.
            case refreshPulled

            /// Called when the user taps "+" or "Create Group".
            case createGroupTapped

            /// Called when the user taps a group in the list.
            case groupTapped(TeamGroup)

            /// Called when the user taps the scanner to join with a code.
            case scanInviteTapped

            /// Called when the user taps "Join" on a pending invitation.
            case invitationJoinTapped(TeamInvitation)

            /// Called when the user taps "Decline" on a pending invitation.
            case invitationDeclineTapped(TeamInvitation)
        }

        @CasePathable
        enum Alert: Equatable {

            /// The user confirmed declining the invitation.
            case confirmDecline(TeamInvitation)
        }
    }

}
