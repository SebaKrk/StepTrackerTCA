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

        /// User tapped the Save button.
        case saveTapped

        // MARK: - Warmup

        /// Toggles warmup on (`WarmUpSession` with defaults) or off (`nil`).
        case warmUpToggled
        /// Updates the warmup duration in minutes.
        case warmUpTimeChanged(Int)
        /// Updates the warmup notes text.
        case warmUpDescriptionChanged(String)
        /// User requested AI generation of warmup notes.
        case warmUpGenerateTapped

        // MARK: - Cooldown

        /// Toggles cooldown on (`CoolDownSession` with defaults) or off (`nil`).
        case coolDownToggled
        /// Updates the cooldown duration in minutes.
        case coolDownTimeChanged(Int)
        /// Updates the cooldown notes text.
        case coolDownDescriptionChanged(String)
        /// User requested AI generation of cooldown notes.
        case coolDownGenerateTapped

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Editor saved a session — parent should handle persistence.
            case saved(TrainingSession)
        }
    }
}
