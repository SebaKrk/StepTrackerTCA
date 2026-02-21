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

            case .saveTapped:
                let session = TrainingSession(id: state.originalId, draft: state.draft)
                state.$plannedWorkouts.withLock { $0[id: session.id] = session }
                return .run { send in
                    await send(.delegate(.saved(session)))
                    await dismiss()
                }

            // MARK: - Warmup

            case .warmUpToggled:
                if state.draft.warmUp == nil {
                    state.draft.warmUp = WarmUpSession(goal: .timeLimit, time: 10, description: nil)
                } else if state.draft.warmUp?.description != nil || state.isGeneratingWarmUpNotes {
                    state.alert = .removeWarmUp
                } else {
                    state.draft.warmUp = nil
                }
                return .none

            case .warmUpTimeChanged(let time):
                guard let warmUp = state.draft.warmUp else { return .none }
                state.draft.warmUp = WarmUpSession(goal: warmUp.goal, time: time, description: warmUp.description)
                return .none

            case .warmUpDescriptionChanged(let text):
                guard let warmUp = state.draft.warmUp else { return .none }
                state.draft.warmUp = WarmUpSession(goal: warmUp.goal, time: warmUp.time, description: text.isEmpty ? nil : text)
                return .none

            case .warmUpGenerateTapped:
                guard !state.draft.workouts.isEmpty else { return .none }
                state.isGeneratingWarmUpNotes = true
                // TODO: call AI with state.draft.workouts context
                return .none

            // MARK: - Cooldown

            case .coolDownToggled:
                if state.draft.coolDown == nil {
                    state.draft.coolDown = CoolDownSession(goal: .timeLimit, time: 10, description: nil)
                } else if state.draft.coolDown?.description != nil || state.isGeneratingCoolDownNotes {
                    state.alert = .removeCoolDown
                } else {
                    state.draft.coolDown = nil
                }
                return .none

            case .coolDownTimeChanged(let time):
                guard let coolDown = state.draft.coolDown else { return .none }
                state.draft.coolDown = CoolDownSession(goal: coolDown.goal, time: time, description: coolDown.description)
                return .none

            case .coolDownDescriptionChanged(let text):
                guard let coolDown = state.draft.coolDown else { return .none }
                state.draft.coolDown = CoolDownSession(goal: coolDown.goal, time: coolDown.time, description: text.isEmpty ? nil : text)
                return .none

            case .coolDownGenerateTapped:
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

            case .workoutAddTapped:
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State())
                return .none

            case .workoutTapped(let workout):
                state.destination = .workoutEditor(WorkoutSessionEditorFeature.State(workout: workout))
                return .none

            case .destination(.presented(.workoutEditor(.delegate(.saved(let workout))))):
                if let index = state.draft.workouts.firstIndex(where: { $0.id == workout.id }) {
                    state.draft.workouts[index] = workout
                } else {
                    state.draft.workouts.append(workout)
                }
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
