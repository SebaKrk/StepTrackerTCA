//
//  WorkoutSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

@Reducer
struct WorkoutSessionEditorFeature {

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
                let workout = WorkoutSessionNew(id: state.originalId, draft: state.draft)
                return .run { send in
                    await send(.delegate(.saved(workout)))
                    await dismiss()
                }

            // MARK: - Exercises

            case .exerciseAddTapped:
                state.destination = .exerciseEditor(ExerciseEditorFeature.State())
                return .none

            case .exerciseTapped(let exercise):
                state.destination = .exerciseEditor(ExerciseEditorFeature.State(exercise: exercise))
                return .none

            case .exerciseMoved(let from, let to):
                state.draft.exercises.move(fromOffsets: from, toOffset: to)
                return .none

            case .exerciseDeleted(let offsets):
                state.draft.exercises.remove(atOffsets: offsets)
                return .none

            case .destination(.presented(.exerciseEditor(.delegate(.saved(let exercise))))):
                if let index = state.draft.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    state.draft.exercises[index] = exercise
                } else {
                    state.draft.exercises.append(exercise)
                }
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
