//
//  ExerciseDetailFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct ExerciseDetailFeature {

    // MARK: - Dependency

    @Dependency(\.exerciseLogClient) var exerciseLogClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.onAppear):
                let exerciseType = state.exerciseType
                return .run { [exerciseLogClient] send in
                    let logs = try await exerciseLogClient.fetchByExerciseType(exerciseType)
                    await send(.logsLoaded(logs))
                }

            case let .logsLoaded(logs):
                state.logs = logs
                return .none

            case .view(.historyRowTapped):
                // Navigation to workout detail handled by parent
                return .none
            }
        }
    }
}
