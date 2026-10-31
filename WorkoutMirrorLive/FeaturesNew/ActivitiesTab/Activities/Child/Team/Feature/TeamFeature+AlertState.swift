//
//  TeamFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == TeamFeature.Action.Alert {

    static func confirmDeclineInvitation(_ invitation: TeamInvitation) -> Self {
        Self {
            TextState(String(localized: "Decline Invitation?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDecline(invitation)) {
                TextState(String(localized: "Decline"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "You can join \(invitation.invite.groupName) later only by scanning the code again."))
        }
    }

    static func confirmDeleteGroup(_ group: TeamGroup) -> Self {
        Self {
            TextState(String(localized: "Delete \(group.name)?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteGroup(group)) {
                TextState(String(localized: "Delete"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "It disappears for everyone with its plans and results. Plan copies in members' Plans stay."))
        }
    }

    static func confirmLeaveGroup(_ group: TeamGroup) -> Self {
        Self {
            TextState(String(localized: "Leave \(group.name)?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmLeaveGroup(group)) {
                TextState(String(localized: "Leave"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "You can come back only with a new invite."))
        }
    }

    static func groupActionFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Update the Group"))
        } message: {
            TextState(message)
        }
    }
}
