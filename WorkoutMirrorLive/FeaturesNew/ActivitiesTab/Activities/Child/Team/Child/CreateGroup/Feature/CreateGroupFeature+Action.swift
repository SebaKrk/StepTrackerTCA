//
//  CreateGroupFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension CreateGroupFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — the group was created.
        case created(TeamGroup)

        /// Internal — creating failed; carries the message to show.
        case failed(String)

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called when the name field changes.
            case nameChanged(String)

            /// Called when the user taps "Create".
            case createTapped

            /// Called when the user taps "Cancel".
            case cancelTapped
        }

        @CasePathable
        enum Delegate {

            /// A new group exists; the sheet is closing.
            case created(TeamGroup)
        }
    }

}
