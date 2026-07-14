//
//  PersonProfileEditFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `PersonProfileEditFeature` state
extension PersonProfileEditFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Preserved ID — ensures upsert updates existing record instead of inserting a new one
        var id: UUID

        /// User's email address
        var email: String

        /// User's first name
        var name: String

        /// User's last name
        var surname: String

        /// User's nickname
        var nickname: String

        // MARK: - Init

        init(profile: UserProfile?) {
            self.id = profile?.id ?? UUID()
            self.email = profile?.email ?? ""
            self.name = profile?.name ?? ""
            self.surname = profile?.surname ?? ""
            self.nickname = profile?.nickname ?? ""
        }
    }

}
