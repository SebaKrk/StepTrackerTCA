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

        /// Internal — leave or delete of a group finished; the listener updates the list.
        case groupActionFinished(TeamGroup.ID)

        /// Internal — leave or delete of a group failed; carries the message to show.
        case groupActionFailed(TeamGroup.ID, String)

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

            /// Called when the owner picks "Delete Group" from a card's context menu.
            case groupDeleteTapped(TeamGroup)

            /// Called when a member picks "Leave Group" from a card's context menu.
            case groupLeaveTapped(TeamGroup)

            /// Called when the user drags a group card to a new place; offsets refer to `orderedGroups`.
            case groupsMoved(from: IndexSet, to: Int)
        }

        @CasePathable
        enum Alert: Equatable {

            /// The user confirmed declining the invitation.
            case confirmDecline(TeamInvitation)

            /// The owner confirmed deleting the group.
            case confirmDeleteGroup(TeamGroup)

            /// The member confirmed leaving the group.
            case confirmLeaveGroup(TeamGroup)
        }
    }

}
