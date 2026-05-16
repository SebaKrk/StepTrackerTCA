//
//  ExerciseEditorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
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

            case .view(.saveTapped):
                var draft = state.draft
                if draft.info != state.originalDraft.info {
                    let trimmed = draft.info.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        draft.plannedSets = nil
                    } else if let parsed = PlannedSet.parse(from: trimmed) {
                        draft.plannedSets = parsed
                    }
                }
                let exercise = ExerciseSession(id: state.originalId, draft: draft)
                return .run { send in
                    await send(.delegate(.saved(exercise)))
                    await dismiss()
                }

            case .view(.deleteTapped):
                state.alert = .confirmDelete(name: state.draft.type.displayName)
                return .none

            case .alert(.presented(.deleteConfirmed)):
                let id = state.originalId
                return .run { send in
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            case .alert:
                return .none

            case .view(.pickExerciseTapped):
                state.destination = .picker(ExercisePickerFeature.State())
                return .none

            case .view(.targetTypeChanged(let type)):
                let currentValue = state.draft.target?.value ?? 10
                state.draft.target = type.makeTarget(value: currentValue)
                return .none

            case .view(.targetValueChanged(let value)):
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
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}
