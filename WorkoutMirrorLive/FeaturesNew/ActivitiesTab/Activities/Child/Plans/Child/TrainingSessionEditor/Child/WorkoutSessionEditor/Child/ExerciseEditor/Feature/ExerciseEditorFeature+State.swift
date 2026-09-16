//
//  ExerciseEditorFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

extension ExerciseEditorFeature {

    @ObservableState
    struct State {

        // MARK: - Mode

        /// Whether the editor is creating a new exercise or editing an existing one.
        let mode: Mode

        // MARK: - Draft

        /// The stable identifier preserved across edits — used as `ExerciseSession.id` on save.
        let originalId: UUID

        /// Snapshot of the draft at the moment the editor was opened — used to detect changes.
        let originalDraft: ExerciseSessionDraft

        /// Mutable copy of the exercise fields being edited.
        var draft: ExerciseSessionDraft

        // MARK: - Shared

        /// Accent color shared with the rest of the app.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .gray

        // MARK: - Alert

        @Presents var alert: AlertState<Action.Alert>?

        // MARK: - Navigation

        /// Navigation destination — exercise picker pushed on top.
        @Presents var destination: Destination.State?

        // MARK: - Computed

        var isSaveDisabled: Bool {
            if draft.type == .unknown {
                return draft.customName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
            }
            return draft == originalDraft
        }

        var navigationTitle: String {
            mode == .create ? "New Exercise" : "Edit Exercise"
        }

        // MARK: - Init

        init(exercise: ExerciseSession? = nil) {
            if let exercise {
                mode = .edit
                originalId = exercise.id
                originalDraft = ExerciseSessionDraft(exercise: exercise)
            } else {
                mode = .create
                originalId = UUID()
                originalDraft = ExerciseSessionDraft()
            }
            draft = originalDraft
        }

        // MARK: - Mode

        /// Determines whether the editor is creating a new exercise or editing an existing one.
        enum Mode {
            /// A new `ExerciseSession` is being created from scratch.
            case create
            /// An existing `ExerciseSession` is being modified.
            case edit
        }
    }
}

// MARK: - ExerciseTargetType

/// Represents the kind of target without an associated value — used as a Picker selection.
/// `.sets` is UI-only: it selects the per-set scheme (`plannedSets`) instead of
/// a single `ExerciseTarget` value.
enum ExerciseTargetType: CaseIterable {
    case reps, calories, meters, seconds, minutes, sets

    var displayName: String {
        switch self {
        case .reps:     return "Reps"
        case .calories: return "Calories"
        case .meters:   return "Meters"
        case .seconds:  return "Seconds"
        case .minutes:  return "Minutes"
        case .sets:     return "Sets"
        }
    }

    /// Builds an `ExerciseTarget` preserving the given value.
    func makeTarget(value: Int) -> ExerciseTarget {
        switch self {
        case .reps:     return .reps(value)
        case .calories: return .calories(value)
        case .meters:   return .meters(value)
        case .seconds:  return .seconds(value)
        case .minutes:  return .minutes(value)
        // Never reached — the reducer routes `.sets` to `plannedSets` before
        // building a target; kept only for switch exhaustiveness.
        case .sets:     return .reps(value)
        }
    }
}

extension ExerciseTarget {

    /// Maps the target to its type (without associated value).
    var targetType: ExerciseTargetType {
        switch self {
        case .reps:     return .reps
        case .calories: return .calories
        case .meters:   return .meters
        case .seconds:  return .seconds
        case .minutes:  return .minutes
        case .rounds:   return .reps
        case .laps:     return .meters
        }
    }

    /// The raw integer value of the target.
    var value: Int {
        switch self {
        case .reps(let v),
             .calories(let v),
             .meters(let v),
             .seconds(let v),
             .minutes(let v),
             .rounds(let v),
             .laps(let v):
            return v
        }
    }
}
