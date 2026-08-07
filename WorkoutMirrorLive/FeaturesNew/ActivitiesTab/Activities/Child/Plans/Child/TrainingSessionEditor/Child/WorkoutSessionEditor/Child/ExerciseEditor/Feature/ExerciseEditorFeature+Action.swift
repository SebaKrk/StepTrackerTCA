//
//  ExerciseEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

extension ExerciseEditorFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        case view(View)

        @CasePathable
        enum View {
            /// User tapped Save.
            case saveTapped
            /// User tapped Delete (edit mode only).
            case deleteTapped
            /// User tapped the exercise type row to open the picker.
            case pickExerciseTapped
            /// User toggled the whole Target section — clears both the single
            /// target and the per-set scheme when disabled.
            case targetToggled(Bool)
            /// User changed the target type (reps → meters → sets, etc.) preserving the current value.
            case targetTypeChanged(ExerciseTargetType)
            /// User changed the target value via stepper.
            case targetValueChanged(Int)
            /// User changed the number of sets via stepper (target type = sets).
            case setsCountChanged(Int)
            /// User changed the reps of a single set (target type = sets).
            case setRepsChanged(index: Int, reps: Int)
        }

        // MARK: - Alert

        case alert(PresentationAction<Alert>)

        enum Alert {
            case deleteConfirmed
        }

        // MARK: - Destination

        case destination(PresentationAction<Destination.Action>)

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Editor saved an exercise — parent should upsert it.
            case saved(ExerciseSession)
            /// Editor deleted an exercise — parent should remove it.
            case deleted(UUID)
        }
    }
}
