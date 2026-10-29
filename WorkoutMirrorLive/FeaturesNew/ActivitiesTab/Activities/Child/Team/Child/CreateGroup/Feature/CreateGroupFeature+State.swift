//
//  CreateGroupFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation

extension CreateGroupFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Group name as typed.
        var name: String = ""

        /// Name other members will see, passed in from the Team tab.
        var displayName: String

        /// A create request is in flight.
        var isSaving = false

        /// Message of the last failed attempt, shown under the form.
        var errorMessage: String?

        // MARK: - Derived

        /// Name without surrounding spaces — what gets saved.
        var trimmedName: String {
            name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// Create is allowed for 3–40 characters and while nothing is saving.
        var isCreateEnabled: Bool {
            (3...40).contains(trimmedName.count) && !isSaving
        }
    }

}
