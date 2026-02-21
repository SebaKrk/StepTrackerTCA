//
//  TrainingSessionEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension TrainingSessionEditorFeature {

    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        case saveTapped

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            case saved(TrainingSession)
        }
    }
}
