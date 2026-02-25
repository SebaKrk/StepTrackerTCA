//
//  WorkoutSessionEditorFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension WorkoutSessionEditorFeature {

    @CasePathable
    enum Action: BindableAction {

        // MARK: - Binding

        case binding(BindingAction<State>)

        // MARK: - View

        /// User tapped the Save button.
        case saveTapped

        /// User tapped the Delete button (edit mode only).
        case deleteTapped

        /// User tapped the + button in the Exercises section.
        case exerciseAddTapped

        /// User tapped an existing exercise row to edit it.
        case exerciseTapped(ExerciseSession)

        /// User reordered exercises via drag & drop.
        case exerciseMoved(from: IndexSet, to: Int)

        /// User deleted exercises via swipe.
        case exerciseDeleted(IndexSet)

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
            /// Editor saved a WOD — parent should update `draft.workouts`.
            case saved(WorkoutSessionNew)
            /// Editor deleted a WOD — parent should remove it.
            case deleted(UUID)
        }
    }
}
