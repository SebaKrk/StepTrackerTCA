//
//  ManageGroupFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == ManageGroupFeature.Action.Alert {

    static let rename = Self {
        TextState(String(localized: "Rename Group?"))
    } actions: {
        ButtonState(action: .confirmRename) {
            TextState(String(localized: "Save"))
        }
        ButtonState(role: .cancel) {
            TextState(String(localized: "Cancel"))
        }
    } message: {
        TextState(String(localized: "Every member sees the new name."))
    }

    static func transfer(to member: TeamMember) -> Self {
        Self {
            TextState(String(localized: "Transfer Ownership?"))
        } actions: {
            ButtonState(action: .confirmTransfer(member)) {
                TextState(String(localized: "Transfer"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "\(member.displayName) will manage the group. You stay as a member."))
        }
    }

    static func remove(_ member: TeamMember) -> Self {
        Self {
            TextState(String(localized: "Remove \(member.displayName)?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmRemove(member)) {
                TextState(String(localized: "Remove"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "They lose access to the group; their results stay on the board. Open invite codes are closed, so show a new one."))
        }
    }

    static let deleteGroup = Self {
        TextState(String(localized: "Delete Group?"))
    } actions: {
        ButtonState(role: .destructive, action: .confirmDelete) {
            TextState(String(localized: "Delete"))
        }
        ButtonState(role: .cancel) {
            TextState(String(localized: "Cancel"))
        }
    } message: {
        TextState(String(localized: "It disappears for everyone with its plans and results. Plan copies in members' Plans stay."))
    }

    static func actionFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Update the Group"))
        } message: {
            TextState(message)
        }
    }
}
