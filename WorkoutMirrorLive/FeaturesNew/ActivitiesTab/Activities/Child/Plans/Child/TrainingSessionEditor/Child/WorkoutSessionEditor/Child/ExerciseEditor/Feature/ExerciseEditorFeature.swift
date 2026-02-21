//
//  ExerciseEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct ExerciseEditorFeature {

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
                let exercise = ExerciseSession(id: state.originalId, draft: state.draft)
                return .run { send in
                    await send(.delegate(.saved(exercise)))
                    await dismiss()
                }

            case .cancelTapped:
                return .run { _ in await dismiss() }

            case .pickExerciseTapped:
                state.destination = .picker(ExercisePickerFeature.State())
                return .none

            case .targetTypeChanged(let type):
                let currentValue = state.draft.target?.value ?? 10
                state.draft.target = type.makeTarget(value: currentValue)
                return .none

            case .targetValueChanged(let value):
                let type = state.draft.target?.targetType ?? .reps
                state.draft.target = type.makeTarget(value: max(1, value))
                return .none

            // MARK: - Destination

            case .destination(.presented(.picker(.delegate(.selected(let type))))):
                state.draft.type = type
                if type != .unknown { state.draft.customName = nil }
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
