//
//  WorkoutPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Feature responsible for previewing a parsed workout before saving.
///
/// Displays the structured TrainingSession with all sections (warmup, workouts, cooldown)
/// and exercises. User can review the parsed data, edit it, or save it.
@Reducer
struct WorkoutPreviewFeature {

    // MARK: - State

    @ObservableState
    struct State {

        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        /// The training session being previewed — updated after editing.
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

            /// Called when user taps "Edit" — opens TrainingSessionEditorFeature.
            case editButtonTapped

            /// Called when user taps "Save" — persists and dismisses.
            case saveButtonTapped

            case warmupToggleTapped
            case cooldownToggleTapped
        }

        enum Delegate {
            /// User saved the workout — passes session up so parent can persist.
            case saved(TrainingSession)
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.editButtonTapped):
                state.destination = .editor(TrainingSessionEditorFeature.State(session: state.trainingSession))
                return .none

            case .view(.saveButtonTapped):
                return .send(.delegate(.saved(state.trainingSession)))

            case .view(.warmupToggleTapped):
                state.isWarmupExpanded.toggle()
                return .none

            case .view(.cooldownToggleTapped):
                state.isCooldownExpanded.toggle()
                return .none

            case .destination(.presented(.editor(.delegate(.saved(let session))))):
                state.trainingSession = session
                return .none

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

}
