//
//  ActivityPlanScoreFeature.swift
//  WorkoutMirrorLive
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Minimal child feature that loads a single `WorkoutPlanScore` for a specific HKWorkout.
///
/// Used in `ActivityDetailsFeature` to display WOD results when a workout was executed
/// according to a training plan.
@Reducer
struct ActivityPlanScoreFeature {

    // MARK: - Dependency

    @Dependency(\.workoutPlanScoreClient) var client

    // MARK: - State

    @ObservableState
    struct State: Equatable {

        /// The HKWorkout UUID used to look up the associated training plan score.
        var hkWorkoutId: UUID

        /// Current loading state of the WOD results.
        var loadState: LoadState = .loading

    }

    // MARK: - Action

    @CasePathable
    enum Action {

        /// Triggers a fetch of the WOD score for `hkWorkoutId`.
        case fetchScore

        /// Fetch completed. `nil` means no plan was associated with this workout.
        case scoreFetched(WorkoutPlanScore?)

        /// Fetch failed — `reportIssue` was called with the underlying error.
        case scoreFetchFailed

    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .fetchScore:
                state.loadState = .loading
                return .run { [id = state.hkWorkoutId] send in
                    do {
                        let score = try await client.fetchByHKWorkoutId(id)
                        await send(.scoreFetched(score))
                    } catch {
                        reportIssue(error)
                        await send(.scoreFetchFailed)
                    }
                }

            case let .scoreFetched(score):
                state.loadState = score.map { .loaded($0) } ?? .notFound
                return .none

            case .scoreFetchFailed:
                state.loadState = .failed
                return .none

            }
        }
    }

}

// MARK: - LoadState

extension ActivityPlanScoreFeature {

    /// Represents the possible states of the WOD results fetch.
    enum LoadState: Equatable {

        /// Fetch is in progress.
        case loading

        /// Score found — workout was executed according to a training plan.
        case loaded(WorkoutPlanScore)

        /// No score found — workout had no associated plan. Nothing is displayed.
        case notFound

        /// Fetch failed — error was reported via `reportIssue`. Nothing is displayed.
        case failed

    }

}
