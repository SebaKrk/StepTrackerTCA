//
//  WorkoutPlanScoreFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// A minimal, reusable child feature that manages fetching and load-state
/// for a training session's workout scores.
///
/// Embed this feature in any parent that needs to display workout history —
/// both `PlanDetailFeature` and future activity-detail features can share it.
@Reducer
struct WorkoutPlanScoreFeature {

    // MARK: - Dependency

    @Dependency(\.workoutPlanScoreClient) var client

    // MARK: - State

    @ObservableState
    struct State {

        /// Identifier of the training session whose scores are loaded.
        var trainingSessionId: UUID

        /// Current loading state of the workout scores.
        var loadState: LoadState = .loading

        /// Convenience accessor — returns scores when loaded, otherwise empty.
        var scores: [WorkoutPlanScore] {
            if case .loaded(let scores) = loadState { return scores }
            return []
        }

        // MARK: - LoadState

        enum LoadState {

            /// Fetch is in progress.
            case loading

            /// Fetch completed successfully with the given scores.
            case loaded([WorkoutPlanScore])

            /// Fetch failed — error was forwarded via `reportIssue`.
            case failed
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Triggers a (re-)fetch of workout scores for the training session.
        case load

        /// Called when scores were successfully fetched from the client.
        case loaded([WorkoutPlanScore])

        /// Called when fetching scores failed.
        case failed
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .load:
                state.loadState = .loading
                return .run { [id = state.trainingSessionId] send in
                    do {
                        let scores = try await client.fetchByTrainingSessionId(id)
                        await send(.loaded(scores))
                    } catch {
                        reportIssue(error)
                        await send(.failed)
                    }
                }

            case .loaded(let scores):
                state.loadState = .loaded(scores)
                return .none

            case .failed:
                state.loadState = .failed
                return .none
            }
        }
    }
}

// MARK: - Preview

#Preview("loading") {
    WorkoutPlanScoreView(
        store: Store(initialState: WorkoutPlanScoreFeature.State(trainingSessionId: UUID())) {
            WorkoutPlanScoreFeature()
        } withDependencies: {
            $0.workoutPlanScoreClient.fetchByTrainingSessionId = { _ in
                try await Task.sleep(for: .seconds(999))
                return []
            }
        },
        onHistoryTapped: {}
    )
    .padding()
}

#Preview("loaded") {
    let session = TrainingSession.previewTrainingSession
    let scores: [WorkoutPlanScore] = [
        WorkoutPlanScore(
            date: Date().addingTimeInterval(-86400 * 7),
            trainingSessionId: session.id,
            hkWorkoutId: UUID(),
            results: [
                WorkoutSessionResult(name: "Weightlifting - Clean and Jerk", description: "", score: "80kg", note: ""),
                WorkoutSessionResult(name: "WOD 1", description: "", score: "11:43", note: "")
            ]
        )
    ]
    var state = WorkoutPlanScoreFeature.State(trainingSessionId: session.id)
    state.loadState = .loaded(scores)
    return WorkoutPlanScoreView(
        store: Store(initialState: state) {
            WorkoutPlanScoreFeature()
        },
        onHistoryTapped: {}
    )
    .padding()
}

#Preview("failed") {
    var state = WorkoutPlanScoreFeature.State(trainingSessionId: UUID())
    state.loadState = .failed
    return WorkoutPlanScoreView(
        store: Store(initialState: state) {
            WorkoutPlanScoreFeature()
        },
        onHistoryTapped: {}
    )
    .padding()
}
