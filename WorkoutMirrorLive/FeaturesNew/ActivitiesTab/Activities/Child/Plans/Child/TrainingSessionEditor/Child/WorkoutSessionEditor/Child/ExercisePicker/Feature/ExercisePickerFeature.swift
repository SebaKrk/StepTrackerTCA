//
//  ExercisePickerFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture

@Reducer
struct ExercisePickerFeature {

    // MARK: - Dependencies

    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .exercisePicked(let type):
                return .run { send in
                    await send(.delegate(.selected(type)))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
