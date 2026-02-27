//
//  TrainingSessionEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels

extension TrainingSessionEditorFeature {

    @CasePathable
    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        /// User tapped the Save button.
        case saveTapped
        /// User tapped the + button in the Workouts section.
        case workoutAddTapped
        
        /// User tapped an existing WOD row to edit it.
        case workoutTapped(WorkoutSessionNew)

        // MARK: - Destination

        case destination(PresentationAction<Destination.Action>)

        // MARK: - Warmup

        /// Toggles warmup on (`WarmUpSession` with defaults) or off (`nil`).
        case warmUpToggled

        /// Updates the warmup duration in minutes.
        case warmUpTimeChanged(Int)

        /// User requested AI generation of warmup description.
        case warmUpGenerateTapped

        // MARK: - Cooldown

        /// Toggles cooldown on (`CoolDownSession` with defaults) or off (`nil`).
        case coolDownToggled

        /// Updates the cooldown duration in minutes.
        case coolDownTimeChanged(Int)

        /// User requested AI generation of cooldown description.
        case coolDownGenerateTapped

        // MARK: - Alert

        case alert(PresentationAction<Alert>)

        enum Alert {
            
            /// User confirmed removing warmup (will delete notes).
            case warmUpRemoveConfirmed
            
            /// User confirmed removing cooldown (will delete notes).
            case coolDownRemoveConfirmed
        }

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {

            /// Editor saved a session — parent should handle persistence.
            case saved(TrainingSession)
        }
    }
}
