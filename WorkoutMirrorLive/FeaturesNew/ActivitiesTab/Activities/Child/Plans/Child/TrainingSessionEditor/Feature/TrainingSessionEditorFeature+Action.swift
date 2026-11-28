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

            /// User tapped Add block or the existing warm-up block — opens the block editor.
            case warmUpBlockEditTapped

            /// User tapped the trash on the warm-up block.
            case warmUpBlockRemoveTapped

            /// User dragged the warm-up block onto its notes (or back) — the two swap places.
            case warmUpPartsSwapped

            /// Toggles cooldown on (`CoolDownSession` with defaults) or off (`nil`).
            case coolDownToggled

            /// Updates the cooldown duration in minutes.
            case coolDownTimeChanged(Int)

            /// User tapped Add block or the existing cool-down block — opens the block editor.
            case coolDownBlockEditTapped

            /// User tapped the trash on the cool-down block.
            case coolDownBlockRemoveTapped

            /// User dragged the cool-down block onto its notes (or back) — the two swap places.
            case coolDownPartsSwapped

            /// User edited the warm-up notes.
            case warmUpNotesChanged(String)

            /// User asked the AI to write the warm-up notes.
            case warmUpGenerateTapped

            /// User asked the AI to write the cool-down notes.
            case coolDownGenerateTapped

            /// User edited the cool-down notes.
            case coolDownNotesChanged(String)

            /// A dragged part landed on another part; the reducer swaps them only if they are partners.
            case sidePartDropped(SidePart, onto: SidePart)

            /// User lifted the grip of a warm-up or cool-down part.
            case sidePartLifted(SidePart)

            /// The grip's drag ended, dropped or cancelled (reported on iOS 27 and later).
            case sidePartDragEnded

            /// A dragged grip entered (`true`) or left (`false`) a warm-up or cool-down part.
            case sidePartTargeted(SidePart, isTargeted: Bool)
        }

        // MARK: - Internal

        case `internal`(Internal)

        @CasePathable
        enum Internal {

            /// AI returned the warm-up notes, or failed.
            case warmUpGenerationResult(Result<String, any Error>)

            /// AI returned the cool-down notes, or failed.
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
            /// User confirmed removing the warm-up block.
            case warmUpBlockRemoveConfirmed
            /// User confirmed removing the cool-down block.
            case coolDownBlockRemoveConfirmed
            /// User confirmed deleting the entire training session.
            case deleteConfirmed
            /// User dismissed the AI generation error alert.
            case generationErrorDismissed
            /// User agreed to send the plan to the AI service while asking for warm-up notes.
            case warmUpGenerationAllowed
            /// User agreed to send the plan to the AI service while asking for cool-down notes.
            case coolDownGenerationAllowed
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
