//
//  PlanPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import OSLog
import SharedModels

@Reducer
struct PlanPreviewFeature {

    @Dependency(\.date) var date
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.trainingSessionClient) var trainingSessionClient
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .view(.downloadTapped):
                guard !state.isDownloaded, !state.isDownloading else { return .none }
                state.isDownloading = true
                state.errorMessage = nil
                let copy = state.plan.session.downloadedTeamCopy(
                    id: uuid(),
                    date: date.now,
                    teamPlanId: TrainingSession.teamPlanId(groupId: state.groupId, day: state.plan.id)
                )
                return .run { [trainingSessionClient] send in
                    try await trainingSessionClient.save(copy)
                    await send(.downloaded)
                } catch: { error, send in
                    Logger.team.error("Download plan failed: \(error.localizedDescription)")
                    await send(.downloadFailed(error.localizedDescription))
                }

            case .view(.closeTapped):
                return .run { [dismiss] _ in await dismiss() }

            case .downloaded:
                state.isDownloading = false
                state.isDownloaded = true
                return .send(.delegate(.downloaded))

            case let .downloadFailed(message):
                state.isDownloading = false
                state.errorMessage = message
                return .none

            case .binding, .delegate:
                return .none
            }
        }
    }
}
