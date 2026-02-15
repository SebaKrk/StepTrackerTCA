//
//  WorkoutPreviewFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

/// Feature responsible for previewing a parsed workout before saving.
///
/// Displays the structured TrainingSession with all sections (warmup, workouts, cooldown)
/// and exercises. User can review the parsed data and optionally edit or save it.
@Reducer
struct WorkoutPreviewFeature {

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss

    // MARK: - State

    @ObservableState
    struct State {

        /// The color representing the training readiness level.
        @Shared(.inMemory(.readinessLevelColor))
        var color: Color = .clear

        /// The training session to preview.
        let trainingSession: TrainingSession
    }

    // MARK: - Action

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        @CasePathable
        enum View {

            /// Called when user taps "Edit" button (placeholder for future).
            case editButtonTapped

            /// Called when user taps "Save" button (placeholder for future).
            case saveButtonTapped
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.editButtonTapped):
                // Dismiss preview and go back to scan plan (idle state)
                return .run { _ in
                    await dismiss()
                }

            case .view(.saveButtonTapped):
                // TODO: Save workout to persistence (Subtask F)
                return .none
            }
        }
    }

}
