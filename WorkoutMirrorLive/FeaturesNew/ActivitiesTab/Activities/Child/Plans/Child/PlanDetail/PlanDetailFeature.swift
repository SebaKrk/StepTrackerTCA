//
//  PlanDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import IdentifiedCollections
import SharedModels
import SwiftUI

@Reducer
struct PlanDetailFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - State

    @ObservableState
    struct State {
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        @Shared(.inMemory("plannedWorkouts"))
        var plannedWorkouts: IdentifiedArrayOf<TrainingSession> = []

        var trainingSession: TrainingSession

        var isWarmupExpanded: Bool = true
        var isCooldownExpanded: Bool = true

        @Presents var destination: Destination.State?
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {
            case doneTapped
            case editTapped
            case warmupToggleTapped
            case cooldownToggleTapped
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
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

            case .destination(.presented(.editor(.delegate(.saved(let session))))):
                state.trainingSession = session
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .none

            case .destination(.presented(.editor(.delegate(.deleted(let id))))):
                state.$plannedWorkouts.withLock { $0.remove(id: id) }
                return .run { _ in await dismiss() }

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
