//
//  TrainingSessionEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension TrainingSessionEditorFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        case view(View)

        @CasePathable
        enum View {
            /// User tapped the Save button.
            case saveTapped

            /// User tapped the Delete button (edit mode only).
            case deleteTapped

            /// User tapped the + button in the Workouts section.
            case workoutAddTapped

            /// User tapped an existing WOD row to edit it.
            case workoutTapped(WorkoutSessionNew)

            /// Toggles warmup on (`WarmUpSession` with defaults) or off (`nil`).
            case warmUpToggled

            /// Updates the warmup duration in minutes.
            case warmUpTimeChanged(Int)

            /// User requested AI generation of warmup description.
            case warmUpGenerateTapped

            /// Toggles cooldown on (`CoolDownSession` with defaults) or off (`nil`).
            case coolDownToggled

            /// Updates the cooldown duration in minutes.
            case coolDownTimeChanged(Int)

            /// User requested AI generation of cooldown description.
            case coolDownGenerateTapped
        }

        // MARK: - Internal

        case `internal`(Internal)

        @CasePathable
        enum Internal {
            /// AI returned a warm-up description.
            case warmUpGenerationResult(Result<String, any Error>)

            /// AI returned a cool-down description.
            case coolDownGenerationResult(Result<String, any Error>)
        }

        // MARK: - Destination

        case destination(PresentationAction<Destination.Action>)

        // MARK: - Alert

        case alert(PresentationAction<Alert>)

        enum Alert {
            /// User confirmed removing warmup (will delete notes).
            case warmUpRemoveConfirmed
            /// User confirmed removing cooldown (will delete notes).
            case coolDownRemoveConfirmed
            /// User confirmed deleting the entire training session.
            case deleteConfirmed
            /// User dismissed the AI generation error alert.
            case generationErrorDismissed
        }

        // MARK: - Delegate

        case delegate(Delegate)

        enum Delegate {
            /// Editor saved a session — parent should handle persistence.
            case saved(TrainingSession)
            /// Editor deleted a session — parent should remove it.
            case deleted(UUID)
        }
    }
}
