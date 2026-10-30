//
//  GroupFeature+AlertState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension AlertState where Action == GroupFeature.Action.Alert {

    // A leaving owner hands the group to the longest-standing member; the last member takes it with them.
    static func leave(isOwner: Bool, successor: TeamMember?) -> Self {
        Self {
            TextState(String(localized: "Leave Group?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmLeave) {
                TextState(String(localized: "Leave"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(leaveMessage(isOwner: isOwner, successor: successor))
        }
    }

    static func deletePlan() -> Self {
        Self {
            TextState(String(localized: "Delete Today's Plan?"))
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletePlan) {
                TextState(String(localized: "Delete"))
            }
            ButtonState(role: .cancel) {
                TextState(String(localized: "Cancel"))
            }
        } message: {
            TextState(String(localized: "Members have already posted results for this plan. They will be deleted with it."))
        }
    }

    static func leaveFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Leave the Group"))
        } message: {
            TextState(message)
        }
    }

    static func deletePlanFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't Delete the Plan"))
        } message: {
            TextState(message)
        }
    }

    static func workoutStartFailed(_ message: String) -> Self {
        Self {
            TextState(String(localized: "Couldn't start the workout"))
        } message: {
            TextState(message)
        }
    }

    private static func leaveMessage(isOwner: Bool, successor: TeamMember?) -> String {
        guard isOwner else {
            return String(localized: "You can come back only with a new invite.")
        }
        guard let successor else {
            return String(localized: "You are the only member, so the group is deleted with its plans and results.")
        }
        return String(localized: "\(successor.displayName), the longest-standing member, becomes the owner. You can come back only with a new invite.")
    }
}
