//
//  WorkoutSessionEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension WorkoutSessionEditorFeature {

    @CasePathable
    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        /// User tapped the Save button.
        case saveTapped

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Editor saved a WOD — parent should update `draft.workouts`.
            case saved(WorkoutSessionNew)
        }
    }
}
