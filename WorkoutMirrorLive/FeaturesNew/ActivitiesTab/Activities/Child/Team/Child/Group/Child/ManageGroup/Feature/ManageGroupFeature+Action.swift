//
//  ManageGroupFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension ManageGroupFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - View Actions

        case view(View)

        /// Text field binding for the name.
        case binding(BindingAction<State>)

        // MARK: - Internal Actions

        /// Internal — the member list changed.
        case membersLoaded([TeamMember])

        /// Internal — listening to members failed.
        case membersFailed

        /// Internal — the group has the new name.
        case renamed(String)

        /// Internal — the group belongs to the given member now.
        case ownershipTransferred(String)

        /// Internal — the member is out of the group.
        case memberRemoved(String)

        /// Internal — the group and everything under it is gone.
        case groupDeleted

        /// Internal — a change failed; carries the message to show.
        case actionFailed(String)

        // MARK: - Alert

        /// Confirmations and the error alert.
        case alert(PresentationAction<Alert>)

        // MARK: - Delegate

        /// Messages for the parent.
        case delegate(Delegate)

        // MARK: - View

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user taps "Try again" after the member list failed.
            case retryTapped

            /// Called when the user taps "Edit" in the toolbar.
            case editTapped

            /// Called when the user taps "Save" in the toolbar; an unchanged name just closes editing.
            case saveNameTapped

            /// Called when the user swipes "Transfer" on a member.
            case transferTapped(TeamMember)

            /// Called when the user swipes "Remove" on a member.
            case removeTapped(TeamMember)

            /// Called when the user taps "Delete Group".
            case deleteGroupTapped
        }

        // MARK: - Alert Actions

        @CasePathable
        enum Alert: Equatable {

            /// The owner confirmed the new name.
            case confirmRename

            /// The owner confirmed handing the group to this member.
            case confirmTransfer(TeamMember)

            /// The owner confirmed removing this member.
            case confirmRemove(TeamMember)

            /// The owner confirmed deleting the group.
            case confirmDelete
        }

        // MARK: - Delegate Actions

        @CasePathable
        enum Delegate {

            /// Name or owner changed — the parent shows the updated group.
            case groupChanged(TeamGroup)

            /// The group is gone — the parent closes its screen.
            case deleted
        }
    }

}
