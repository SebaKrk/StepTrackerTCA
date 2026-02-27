//
//  ExerciseEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension ExerciseEditorFeature {

    @CasePathable
    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        /// User tapped Save.
        case saveTapped

        /// User tapped Cancel.
        case cancelTapped

        /// User tapped the exercise type row to open the picker.
        case pickExerciseTapped

        /// User changed the target type (reps → meters, etc.) preserving the current value.
        case targetTypeChanged(ExerciseTargetType)

        /// User changed the target value via stepper.
        case targetValueChanged(Int)

        // MARK: - Destination

        case destination(PresentationAction<Destination.Action>)

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Editor saved an exercise — parent should upsert it.
            case saved(ExerciseSession)
        }
    }
}
