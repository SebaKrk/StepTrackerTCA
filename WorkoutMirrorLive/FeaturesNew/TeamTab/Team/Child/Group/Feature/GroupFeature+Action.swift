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

        /// Internal — the user is no longer a member.
        case left

        /// Internal — leaving failed; carries the message to show.
        case leaveFailed(String)

        /// Leave confirmation and error alerts.
        case alert(PresentationAction<Alert>)

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user picks "Leave Group" from the menu.
            case leaveTapped
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
