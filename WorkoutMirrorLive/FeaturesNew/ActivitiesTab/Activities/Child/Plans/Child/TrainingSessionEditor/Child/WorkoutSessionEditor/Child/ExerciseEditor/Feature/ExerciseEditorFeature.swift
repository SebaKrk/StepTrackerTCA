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
                // Sets are edited structurally in the Sets section — Notes is a
                // plain note and never re-parsed into plannedSets.
                let exercise = ExerciseSession(id: state.originalId, draft: state.draft)
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

            case .view(.targetToggled(let enabled)):
                state.draft.target = enabled ? .reps(10) : nil
                state.draft.plannedSets = nil
                return .none

            case .view(.targetTypeChanged(let type)):
                // The value survives mode switches: reps ⇄ sets carry it over.
                let currentValue = state.draft.target?.value
                    ?? state.draft.plannedSets?.first?.reps
                    ?? 10
                if type == .sets {
                    state.draft.target = nil
                    if state.draft.plannedSets == nil {
                        state.draft.plannedSets = Array(
                            repeating: PlannedSet(reps: currentValue), count: 3
                        )
                    }
                } else {
                    state.draft.plannedSets = nil
                    state.draft.target = type.makeTarget(value: currentValue)
                }
                return .none

            case .view(.targetValueChanged(let value)):
                let type = state.draft.target?.targetType ?? .reps
                state.draft.target = type.makeTarget(value: max(1, value))
                return .none

            case .view(.setsCountChanged(let count)):
                guard var sets = state.draft.plannedSets, count >= 1 else { return .none }
                while sets.count < count { sets.append(sets.last ?? PlannedSet(reps: 10)) }
                while sets.count > count { sets.removeLast() }
                state.draft.plannedSets = sets
                return .none

            case .view(.setRepsChanged(let index, let reps)):
                guard var sets = state.draft.plannedSets, sets.indices.contains(index) else { return .none }
                // Reps-only edit — the scanned per-set weight suggestion survives.
                sets[index] = PlannedSet(reps: max(1, reps), suggestedWeight: sets[index].suggestedWeight)
                state.draft.plannedSets = sets
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
