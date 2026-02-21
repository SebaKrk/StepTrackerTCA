//
//  ExercisePickerFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension ExercisePickerFeature {

    @CasePathable
    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        /// User tapped an exercise row — selected and should be returned to caller.
        case exercisePicked(ExerciseType)

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Picker has a confirmed selection ready for the parent.
            case selected(ExerciseType)
        }
    }
}
