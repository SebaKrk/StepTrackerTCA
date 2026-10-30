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
                guard state.canDownload, !state.isDownloaded, !state.isDownloading else { return .none }
                state.isDownloading = true
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

            case .view(.startWorkoutTapped):
                guard state.canDownload, state.isDownloaded else { return .none }
                state.devicePicker = DeviceFeature.State()
                return .none

            case .view(.closeTapped):
                return .run { [dismiss] _ in await dismiss() }

            case .devicePicker(.presented(.select(let device))):
                state.devicePicker = nil
                return .send(.delegate(.startWorkout(device)))

            case .devicePicker:
                return .none

            case .downloaded:
                state.isDownloading = false
                state.isDownloaded = true
                return .send(.delegate(.downloaded))

            case let .downloadFailed(message):
                state.isDownloading = false
                state.alert = .downloadFailed(message)
                return .none

            case .alert:
                return .none

            case .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$devicePicker, action: \.devicePicker) {
            DeviceFeature()
        }
    }
}
