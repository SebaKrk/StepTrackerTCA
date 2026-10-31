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
                state.configuration = ConfigurationFeature.State(
                    lockedWorkout: WorkoutType(hkType: state.plan.session.activity.hkType) ?? .cross
                )
                return .none

            case .view(.closeTapped):
                return .run { [dismiss] _ in await dismiss() }

            case let .configuration(.presented(.delegate(.start(_, device)))):
                state.configuration = nil
                // `nil` never reaches here: the picker always commits a device before it delegates.
                guard let device else { return .none }
                return .send(.delegate(.startWorkout(device)))

            case .configuration:
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
        .ifLet(\.$configuration, action: \.configuration) {
            ConfigurationFeature()
        }
    }
}
