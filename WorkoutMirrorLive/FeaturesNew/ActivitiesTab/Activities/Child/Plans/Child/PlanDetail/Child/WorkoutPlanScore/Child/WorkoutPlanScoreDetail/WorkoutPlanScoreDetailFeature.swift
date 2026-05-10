//
//  WorkoutPlanScoreDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import HealthHub
import HealthKit
import IssueReporting
import SharedModels

/// Displays the WOD results for a single `WorkoutPlanScore` execution
/// and allows navigating to the corresponding `ActivityDetails` screen.
///
/// Tapping "View Activity" fetches the linked `HKWorkout` from HealthKit
/// and presents `ActivityDetailsFeature` in a full-screen cover.
@Reducer
struct WorkoutPlanScoreDetailFeature {

    // MARK: - Dependency

    @Dependency(\.activityClient) var activityClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient

    // MARK: - State

    @ObservableState
    struct State {

        /// The workout plan score being displayed.
        var score: WorkoutPlanScore

        /// Whether the HKWorkout fetch is in progress.
        /// Drives the loading indicator on the "View Activity" toolbar button.
        var isLoadingActivity: Bool = false

        /// Navigation destination — currently only `activityDetails`.
        @Presents var destination: Destination.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// View-originated actions.
        case view(View)

        /// Destination navigation actions managed by `@Presents`.
        case destination(PresentationAction<Destination.Action>)

        /// Called when the HKWorkout and max heart rate were successfully fetched.
        case activityLoaded(HKWorkout, Double)

        /// Called when the HKWorkout fetch failed or returned nil.
        case activityLoadFailed

        @CasePathable
        enum View {
            /// User tapped "View Activity" — fetches the HKWorkout and navigates to ActivityDetails.
            case viewActivityTapped
        }
    }

    // MARK: - Destination

    @Reducer
    enum Destination {
        case activityDetails(ActivityDetailsFeature)
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.viewActivityTapped):
                state.isLoadingActivity = true
                return .run { [id = state.score.hkWorkoutId, activityClient, maxHeartRateClient] send in
                    do {
                        guard let workout = try await activityClient.fetchWorkoutById(id) else {
                            await send(.activityLoadFailed)
                            return
                        }
                        let maxHR = await maxHeartRateClient.forWorkout(workout)
                        await send(.activityLoaded(workout, maxHR))
                    } catch {
                        reportIssue(error)
                        await send(.activityLoadFailed)
                    }
                }

            case let .activityLoaded(workout, maxHR):
                state.isLoadingActivity = false
                state.destination = .activityDetails(
                    ActivityDetailsFeature.State(workout: workout, maxHeartRate: maxHR)
                )
                return .none

            case .activityLoadFailed:
                // TODO: Surface a user-visible alert when the linked HKWorkout cannot be
                // resolved (likely deleted from HealthKit by the user). Today fails silently:
                // toolbar spinner clears, navigation doesn't happen, user sees nothing.
                state.isLoadingActivity = false
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
