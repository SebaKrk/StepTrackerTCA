//
//  PersonProfileEditFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import ComposableArchitecture
import Foundation
import IssueReporting
import SharedModels

@Reducer
struct PersonProfileEditFeature {

    // MARK: - Dependency

    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .view(.saveButtonTapped):
                let profile = UserProfile(
                    id: state.id,
                    email: state.email,
                    name: state.name,
                    surname: state.surname,
                    nickname: state.nickname
                )
                return .run { send in
                    try await userProfileClient.save(profile)
                    await send(.delegate(.profileSaved))
                } catch: { error, _ in
                    reportIssue(error)
                }

            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }

}
