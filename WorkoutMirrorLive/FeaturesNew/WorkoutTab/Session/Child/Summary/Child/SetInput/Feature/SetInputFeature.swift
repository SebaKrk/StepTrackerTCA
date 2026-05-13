//
//  SetInputFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct SetInputFeature {

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            // MARK: - Simple exercise (WOD)

            case let .view(.updateExerciseReps(exerciseIndex, text)):
                guard exerciseIndex < state.exercises.count else { return .none }
                state.exercises[exerciseIndex].actualReps = text.isEmpty ? nil : text
                return .none

            case let .view(.updateExerciseWeight(exerciseIndex, text)):
                guard exerciseIndex < state.exercises.count else { return .none }
                state.exercises[exerciseIndex].actualWeight = Double(text)
                return .none

            // MARK: - Per-set (Strength)

            case let .view(.updateSetReps(exerciseIndex, setIndex, text)):
                guard exerciseIndex < state.exercises.count,
                      let sets = state.exercises[exerciseIndex].sets,
                      setIndex < sets.count
                else { return .none }
                state.exercises[exerciseIndex].sets?[setIndex].reps = Int(text) ?? 0
                return .none

            case let .view(.updateSetWeight(exerciseIndex, setIndex, text)):
                guard exerciseIndex < state.exercises.count,
                      let sets = state.exercises[exerciseIndex].sets,
                      setIndex < sets.count
                else { return .none }
                state.exercises[exerciseIndex].sets?[setIndex].weight = Double(text)
                return .none

            // MARK: - Confirm / Cancel

            case .view(.addTapped):
                state.confirmed = true
                return .run { _ in await self.dismiss() }

            case .view(.cancelTapped):
                state.confirmed = false
                return .run { _ in await self.dismiss() }
            }
        }
    }
}
