//
//  ManageGroupFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 30/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

extension ManageGroupFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// The group being managed.
        var group: TeamGroup

        /// Current account id — the owner, marked in the list and never removable.
        var myUid: String

        /// Accent of the Team tab.
        var color: Color

        /// Name in the text field; saved only through the confirmation.
        var name: String

        /// "Edit" in the toolbar opened the name for typing.
        var isEditingName = false

        /// Members, earliest first.
        var members: [TeamMember] = []

        /// Loading state of the member list.
        var viewState: ViewState = .loading

        /// The change in flight, so the spinner shows where the user tapped; `nil` when idle.
        var working: Working?

        // MARK: - Alert

        /// Confirmation before every change, or the error after a failed one.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Init

        init(group: TeamGroup, myUid: String, color: Color) {
            self.group = group
            self.myUid = myUid
            self.color = color
            self.name = group.name
        }

        // MARK: - Derived

        /// Group names run 3–40 characters, like at creation.
        var trimmedName: String {
            name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// The name changed and is valid.
        var canSaveName: Bool {
            (3...40).contains(trimmedName.count) && trimmedName != group.name && !isWorking
        }

        /// Any change is in flight.
        var isWorking: Bool {
            working != nil
        }

        /// The member whose menu is replaced by a spinner; `nil` when no member change is in flight.
        var workingMemberUid: String? {
            switch working {
            case .transfer(let uid), .remove(let uid):
                return uid
            case .rename, .delete, nil:
                return nil
            }
        }

        /// A change the owner confirmed and the app is sending.
        enum Working: Equatable {

            /// Saving the new name.
            case rename

            /// Handing the group to this member.
            case transfer(String)

            /// Removing this member.
            case remove(String)

            /// Deleting the whole group.
            case delete
        }
    }

}
