//
//  OnboardingFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `OnboardingFeature` state
extension OnboardingFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// First name as typed.
        var name: String = ""

        /// Last name as typed, optional — nothing in the app requires it.
        var surname: String = ""

        /// The name other people will see.
        var nickname: String = ""

        /// Whether the person has touched the nickname field themselves.
        ///
        /// Once they have, typing in the name fields stops overwriting it —
        /// a proposal that fights back while you correct a typo is worse than
        /// no proposal at all.
        var hasEditedNickname: Bool = false

        /// Whether the profile is being written right now.
        var isSaving: Bool = false

        /// The profile already on this device, when there is one.
        ///
        /// A half-filled profile from an earlier build is completed in place.
        /// Writing a fresh row instead would leave the old one behind, and
        /// `fetch()` returns whichever was touched last.
        var existing: UserProfile?

        // MARK: - Lifecycle

        init(existing: UserProfile? = nil) {
            self.existing = existing
            self.name = existing?.name ?? ""
            self.surname = existing?.surname ?? ""
            self.nickname = existing?.nickname ?? ""
            self.hasEditedNickname = !(existing?.nickname ?? "").isEmpty
        }

        // MARK: - Computed

        /// A name and a nickname are enough; the surname is not required.
        var canContinue: Bool {
            !isSaving
                && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
