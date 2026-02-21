//
//  WorkoutSessionEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

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

            case .delegate:
                return .none
            }
        }
    }
}
