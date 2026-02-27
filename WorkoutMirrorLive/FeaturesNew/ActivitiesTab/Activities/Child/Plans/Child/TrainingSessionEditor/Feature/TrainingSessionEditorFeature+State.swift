//
//  TrainingSessionEditorFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import IdentifiedCollections
import SharedModels
import SwiftUI

extension TrainingSessionEditorFeature {

    @ObservableState
    struct State {

        /// Whether the editor is creating a new session or editing an existing one.
        let mode: Mode

        /// The stable identifier preserved across edits — used as `TrainingSession.id` on save.
        let originalId: UUID
        
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

        /// In-memory store of planned workouts, shared across features.
        @Shared(.inMemory("plannedWorkouts"))
        var plannedWorkouts: IdentifiedArrayOf<TrainingSession> = []

        // MARK: - Computed

        var isSaveDisabled: Bool {
            draft.title.trimmingCharacters(in: .whitespaces).isEmpty
        }

        var navigationTitle: String {
            mode == .create ? "New Workout" : "Edit Workout"
        }

        // MARK: - Init

        init(session: TrainingSession? = nil) {
            if let session {
                mode = .edit
                originalId = session.id
                draft = TrainingSessionDraft(session: session)
            } else {
                mode = .create
                originalId = UUID()
                draft = TrainingSessionDraft()
            }
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
