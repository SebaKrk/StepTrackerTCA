//
//  WorkoutSessionEditorFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

extension WorkoutSessionEditorFeature {

    @ObservableState
    struct State {

        // MARK: - Mode

        let mode: Mode

        // MARK: - Draft

        /// The stable identifier preserved across edits — used as `WorkoutSessionNew.id` on save.
        let originalId: UUID

        /// Snapshot of the draft at the moment the editor was opened — used to detect changes.
        let originalDraft: WorkoutSessionDraft

        /// Mutable copy of the workout fields being edited.
        var draft: WorkoutSessionDraft

        // MARK: - Shared

        /// Accent color shared with the rest of the app.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        // MARK: - Alert

        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Navigation

        /// Navigation destination — exercise editor presented as a sheet.
        @Presents var destination: Destination.State?

        // MARK: - Computed

        var isSaveDisabled: Bool {
            draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft.exercises.isEmpty || draft == originalDraft
        }

        var navigationTitle: String {
            mode == .create ? "New WOD" : "Edit WOD"
        }

        // MARK: - Init

        init(workout: WorkoutSessionNew? = nil) {
            if let workout {
                mode = .edit
                originalId = workout.id
                originalDraft = WorkoutSessionDraft(workout: workout)
            } else {
                mode = .create
                originalId = UUID()
                originalDraft = WorkoutSessionDraft()
            }
            draft = originalDraft
        }

        // MARK: - Mode

        /// Determines whether the editor is creating a new WOD or editing an existing one.
        enum Mode {
            /// A new `WorkoutSessionNew` is being created from scratch.
            case create
            /// An existing `WorkoutSessionNew` is being modified.
            case edit
        }
    }
}
