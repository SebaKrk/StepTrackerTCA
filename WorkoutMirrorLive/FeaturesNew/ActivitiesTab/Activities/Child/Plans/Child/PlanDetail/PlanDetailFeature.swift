//
//  PlanDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@Reducer
struct PlanDetailFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - State

    @ObservableState
    struct State {

        /// Tint color shared across the app (readiness level).
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        /// The training plan being displayed.
        var trainingSession: TrainingSession

        /// Controls whether the warm-up section is expanded.
        var isWarmupExpanded: Bool = true

        /// Controls whether the cool-down section is expanded.
        var isCooldownExpanded: Bool = true

        /// Child feature managing fetch and load state for workout scores.
        var scoreLoader: WorkoutPlanScoreFeature.State

        @Presents var destination: Destination.State?

        init(trainingSession: TrainingSession) {
            self.trainingSession = trainingSession
            self.scoreLoader = WorkoutPlanScoreFeature.State(trainingSessionId: trainingSession.id)
        }
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        /// Forwarded actions from the score loader child feature.
        case scoreLoader(WorkoutPlanScoreFeature.Action)

        /// View-originated actions — see `View` enum.
        case view(View)

        /// Delegate actions sent to the parent feature.
        case delegate(Delegate)

        /// Destination navigation actions managed by `@Presents`.
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Triggered when the view appears — starts loading workout history.
            case viewDidAppear

            /// Dismisses the plan detail screen.
            case doneTapped

            /// Opens the training session editor.
            case editTapped

            /// Toggles the warm-up section visibility.
            case warmupToggleTapped

            /// Toggles the cool-down section visibility.
            case cooldownToggleTapped

            /// Starts a workout session with this plan — forwarded to parent via delegate.
            case startWorkoutTapped

            /// Opens the workout history list for this plan.
            case historyTapped

            /// Opens the QR share sheet for this plan.
            case shareTapped
        }

        enum Delegate {

            /// Session was saved — parent should update the collection.
            case saved(TrainingSession)

            /// Session was deleted — parent should remove it and dismiss.
            case deleted(UUID)

            /// User tapped "Start Workout" — parent should present the session screen.
            case startWorkout(TrainingSession)
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.scoreLoader, action: \.scoreLoader) {
            WorkoutPlanScoreFeature()
        }
        Reduce { state, action in
            switch action {

                // MARK: - View Action

            case .view(.viewDidAppear):
                return .send(.scoreLoader(.load))

            case .view(.doneTapped):
                return .run { _ in await dismiss() }

            case .view(.editTapped):
                state.destination = .editor(TrainingSessionEditorFeature.State(session: state.trainingSession))
                return .none

            case .view(.warmupToggleTapped):
                state.isWarmupExpanded.toggle()
                return .none

            case .view(.cooldownToggleTapped):
                state.isCooldownExpanded.toggle()
                return .none

            case .view(.startWorkoutTapped):
                return .send(.delegate(.startWorkout(state.trainingSession)))

            case .view(.historyTapped):
                state.destination = .history(
                    WorkoutPlanScoreListFeature.State(trainingSession: state.trainingSession)
                )
                return .none

            case .view(.shareTapped):
                state.destination = .share(SharePlanFeature.State(plan: state.trainingSession))
                return .none

                // MARK: - Destination

            case .destination(.presented(.editor(.delegate(.saved(let session))))):
                state.trainingSession = session
                return .send(.delegate(.saved(session)))

            case .destination(.presented(.editor(.delegate(.deleted(let id))))):
                return .run { send in
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            case .destination(.dismiss):
                return .send(.scoreLoader(.load))

            case .destination:
                return .none

                // MARK: - Score Loader

            case .scoreLoader:
                return .none

                // MARK: - Delegate

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
