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
            .functional,
            .endurance,
            .boxing,
            .running
        ]

        // MARK: - Shared

        /// Accent color for the gradient background, shared with the rest of the app.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        // MARK: - Drag

        /// Warm-up or cool-down part whose grip the user lifted; only its partner may light up as a drop target.
        var draggedSidePart: SidePart?

        /// Partner part the dragged grip is hovering over — highlighted, `nil` when none.
        var sidePartDropTarget: SidePart?

        // MARK: - Navigation

        /// Navigation destination — WOD or side-block editor pushed on top.
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

        /// Warm-up card, ready to render.
        var warmUpSection: SideSection {
            SideSection(
                isOn: draft.warmUp != nil,
                minutes: draft.warmUp?.time ?? 10,
                notes: draft.warmUp?.description ?? "",
                block: draft.warmUp?.block,
                order: draft.warmUp?.resolvedOrder ?? .notesFirst,
                blockPart: .warmUpBlock,
                notesPart: .warmUpNotes,
                liftedPart: draggedSidePart,
                dropTarget: sidePartDropTarget
            )
        }

        /// Cool-down card, ready to render.
        var coolDownSection: SideSection {
            SideSection(
                isOn: draft.coolDown != nil,
                minutes: draft.coolDown?.time ?? 10,
                notes: draft.coolDown?.description ?? "",
                block: draft.coolDown?.block,
                order: draft.coolDown?.resolvedOrder ?? .blockFirst,
                blockPart: .coolDownBlock,
                notesPart: .coolDownNotes,
                liftedPart: draggedSidePart,
                dropTarget: sidePartDropTarget
            )
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
