//
//  TrainingSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

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
                state.draft.warmUp = state.draft.warmUp == nil
                    ? WarmUpSession(goal: .timeLimit, time: 10, description: nil)
                    : nil
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
                state.draft.coolDown = state.draft.coolDown == nil
                    ? CoolDownSession(goal: .timeLimit, time: 10, description: nil)
                    : nil
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

            case .delegate:
                return .none
            }
        }
    }
}
