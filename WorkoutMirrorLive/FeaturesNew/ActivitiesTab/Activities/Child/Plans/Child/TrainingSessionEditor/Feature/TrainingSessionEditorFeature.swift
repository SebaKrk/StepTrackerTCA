//
//  TrainingSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

@Reducer
struct TrainingSessionEditorFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .view(.saveTapped):
                let session = TrainingSession(id: state.originalId, draft: state.draft)
                return .run { send in
                    await send(.delegate(.saved(session)))
                    await dismiss()
                }

            case .view(.deleteTapped):
                state.alert = .confirmDelete(title: state.draft.title)
                return .none

            case .alert(.presented(.deleteConfirmed)):
                let id = state.originalId
                return .run { send in
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            // MARK: - Warmup

            case .view(.warmUpToggled):
                if state.draft.warmUp == nil {
                    state.draft.warmUp = WarmUpSession(goal: .timeLimit, time: 10)
                } else if state.draft.warmUp?.description.isEmpty == false || state.isGeneratingWarmUpNotes {
                    state.alert = .removeWarmUp
                } else {
                    state.draft.warmUp = nil
                }
                return .none

            case .view(.warmUpTimeChanged(let time)):
                state.draft.warmUp?.time = time
                return .none

            case .view(.warmUpGenerateTapped):
                guard !state.draft.workouts.isEmpty else { return .none }
                state.isGeneratingWarmUpNotes = true
                // TODO: call AI with state.draft.workouts context
                return .none

            // MARK: - Cooldown

            case .view(.coolDownToggled):
                if state.draft.coolDown == nil {
                    state.draft.coolDown = CoolDownSession(goal: .timeLimit, time: 10)
                } else if state.draft.coolDown?.description.isEmpty == false || state.isGeneratingCoolDownNotes {
                    state.alert = .removeCoolDown
                } else {
                    state.draft.coolDown = nil
                }
                return .none

            case .view(.coolDownTimeChanged(let time)):
                state.draft.coolDown?.time = time
                return .none

            case .view(.coolDownGenerateTapped):
                guard !state.draft.workouts.isEmpty else { return .none }
                state.isGeneratingCoolDownNotes = true
                // TODO: call AI with state.draft.workouts context
                return .none

            // MARK: - Alert

            case .alert(.presented(.warmUpRemoveConfirmed)):
                state.draft.warmUp = nil
                state.isGeneratingWarmUpNotes = false
                return .none

            case .alert(.presented(.coolDownRemoveConfirmed)):
                state.draft.coolDown = nil
                state.isGeneratingCoolDownNotes = false
                return .none

            case .alert:
                return .none

            // MARK: - Workouts

            case .view(.workoutAddTapped):
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State())
                return .none

            case .view(.workoutTapped(let workout)):
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State(workout: workout))
                return .none

            case .destination(.presented(.workoutEditor(.delegate(.saved(let workout))))):
                if let index = state.draft.workouts.firstIndex(where: { $0.id == workout.id }) {
                    state.draft.workouts[index] = workout
                } else {
                    state.draft.workouts.append(workout)
                }
                return .none

            case .destination(.presented(.workoutEditor(.delegate(.deleted(let id))))):
                state.draft.workouts.removeAll { $0.id == id }
                return .none

            case .destination:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}
