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
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

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
        case delegate(Delegate)

        @CasePathable
        enum View {
            case doneTapped
            case editTapped
            case warmupToggleTapped
            case cooldownToggleTapped
        }

        enum Delegate {
            /// Session was saved — parent should update the collection.
            case saved(TrainingSession)
            /// Session was deleted — parent should remove it and dismiss.
            case deleted(UUID)
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
                return .send(.delegate(.saved(session)))

            case .destination(.presented(.editor(.delegate(.deleted(let id))))):
                return .run { send in
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
