//
//  CreateGroupFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct CreateGroupFeature {

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.teamClient) var teamClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - View

            case let .view(.nameChanged(name)):
                state.name = name
                state.errorMessage = nil
                return .none

            case .view(.createTapped):
                guard state.isCreateEnabled else { return .none }
                state.isSaving = true
                state.errorMessage = nil
                return .run { [name = state.trimmedName, displayName = state.displayName, teamClient] send in
                    let group = try await teamClient.createGroup(name, displayName)
                    await send(.created(group))
                } catch: { error, send in
                    Logger.team.error("Create group failed: \(error.localizedDescription)")
                    await send(.failed(error.localizedDescription))
                }

            case .view(.cancelTapped):
                return .run { [dismiss] _ in await dismiss() }

            // MARK: - Internal

            case let .created(group):
                state.isSaving = false
                return .run { [dismiss] send in
                    await send(.delegate(.created(group)))
                    await dismiss()
                }

            case let .failed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
