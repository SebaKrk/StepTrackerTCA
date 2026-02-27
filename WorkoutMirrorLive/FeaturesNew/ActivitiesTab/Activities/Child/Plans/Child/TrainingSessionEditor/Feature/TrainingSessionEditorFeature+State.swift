//
//  TrainingSessionEditorFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension TrainingSessionEditorFeature {

    @ObservableState
    struct State {

        /// Whether the editor is creating a new session or editing an existing one.
        let mode: Mode

        /// The stable identifier preserved across edits — used as `TrainingSession.id` on save.
        let originalId: UUID

        /// Snapshot of the draft at the moment the editor was opened — used to detect changes.
        let originalDraft: TrainingSessionDraft

        /// Mutable copy of the session fields being edited.
        var draft: TrainingSessionDraft

        /// Activity types available for selection in the editor.
        static let supportedActivities: [WorkoutActivityType] = [
            .crossTraining,
            .boxing,
            .running
        ]

        // MARK: - Shared

        /// Accent color for the gradient background, shared with the rest of the app.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        // MARK: - AI

        /// True while the AI is generating warmup notes.
        var isGeneratingWarmUpNotes: Bool = false
        
        /// True while the AI is generating cooldown notes.
        var isGeneratingCoolDownNotes: Bool = false

        // MARK: - Navigation

        /// Navigation destination — WOD editor pushed on top.
        @Presents var destination: Destination.State?

        // MARK: - Alert

        /// Confirmation alert shown when user tries to remove warmup/cooldown with existing notes.
        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Computed

        var isSaveDisabled: Bool {
            draft.title.trimmingCharacters(in: .whitespaces).isEmpty || draft.workouts.isEmpty || draft == originalDraft
        }

        var navigationTitle: String {
            mode == .create ? "New Workout" : "Edit Workout"
        }

        // MARK: - Init

        init(session: TrainingSession? = nil) {
            if let session {
                mode = .edit
                originalId = session.id
                originalDraft = TrainingSessionDraft(session: session)
            } else {
                mode = .create
                originalId = UUID()
                originalDraft = TrainingSessionDraft()
            }
            draft = originalDraft
        }

        // MARK: - Mode

        /// Determines whether the editor is creating a new session or editing an existing one.
        enum Mode {
            /// A new `TrainingSession` is being created from scratch.
            case create
            /// An existing `TrainingSession` is being modified.
            case edit
        }
    }
    
}
