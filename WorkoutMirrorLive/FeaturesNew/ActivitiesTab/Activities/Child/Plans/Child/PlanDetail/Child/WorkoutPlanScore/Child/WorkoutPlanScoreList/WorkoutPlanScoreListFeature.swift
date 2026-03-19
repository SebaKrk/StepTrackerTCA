//
//  WorkoutPlanScoreListFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct WorkoutPlanScoreListFeature {

    // MARK: - State

    @ObservableState
    struct State {

        /// The training session whose history is displayed.
        var trainingSession: TrainingSession

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

        case view(View)
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Triggered when the view appears — starts loading history.
            case viewDidAppear

            /// User tapped a score row — navigate to detail.
            case scoreTapped(WorkoutPlanScore)

            /// User tapped retry after a load failure.
            case retryTapped

            /// User tapped "Porównaj" with the selected scores.
            case compareTapped([WorkoutPlanScore])
        }
    }

    // MARK: - Destination

    @Reducer
    enum Destination {

        /// Show detail of a single workout score.
        case detail(WorkoutPlanScoreDetailFeature)

        /// Compare two or more selected workout scores.
        case comparison(WorkoutPlanScoreComparisonFeature)
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

            case .view(.retryTapped):
                return .send(.scoreLoader(.load))

            case let .view(.scoreTapped(score)):
                state.destination = .detail(WorkoutPlanScoreDetailFeature.State(score: score))
                return .none

            case let .view(.compareTapped(scores)):
                state.destination = .comparison(WorkoutPlanScoreComparisonFeature.State(scores: scores))
                return .none

                // MARK: - Destination

            case .destination:
                return .none

                // MARK: - Score Loader

            case .scoreLoader:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
