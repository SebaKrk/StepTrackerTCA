//
//  OnboardingFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation
import IssueReporting
import SharedModels

@Reducer
struct OnboardingFeature {

    // MARK: - Dependency

    @Dependency(\.userProfileClient) var userProfileClient
    @Dependency(\.teamClient) var teamClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

                // MARK: - Binding
            case .binding(\.nickname):
                state.hasEditedNickname = true
                return .none

            case .binding(\.name), .binding(\.surname):
                guard !state.hasEditedNickname else { return .none }
                state.nickname = NicknameSuggestion.make(
                    name: state.name,
                    surname: state.surname
                )
                return .none

            case .binding:
                return .none

                // MARK: - Action
            case let .saveFinished(didSucceed):
                state.isSaving = false

                guard didSucceed else { return .none }

                // The screen closes itself rather than handing the parent a
                // delegate to nil the state on. The parent's write landed
                // before `ifLet` ran, so the child was already gone when its
                // own action arrived.
                return .run { _ in await dismiss() }

                // MARK: - View Action
            case .view(.continueTapped):
                guard state.canContinue else { return .none }
                state.isSaving = true

                let profile = UserProfile(
                    id: state.existing?.id ?? uuid(),
                    email: state.existing?.email ?? "",
                    name: state.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    surname: state.surname.trimmingCharacters(in: .whitespacesAndNewlines),
                    nickname: state.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    onboardedAt: state.existing?.onboardedAt ?? now
                )

                return .run { [userProfileClient, teamClient] send in
                    // Offline must not hold anyone at the door. The account is
                    // created on the next launch instead; nothing stored here
                    // depends on it yet.
                    var completed = profile
                    completed.accountUid = (try? await teamClient.ensureSignedIn()) ?? ""

                    try await userProfileClient.save(completed)
                    await send(.saveFinished(true))
                } catch: { error, send in
                    reportIssue(error)
                    await send(.saveFinished(false))
                }
            }
        }
    }
}
