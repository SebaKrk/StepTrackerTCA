//
//  SummaryFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension SummaryFeature {

    @CasePathable
    enum Action: ViewAction {

        // MARK: - Actions

        /// Responsible for changing the state of the view.
        case changeViewState(SummaryState)

        /// Initiates the workout summary check process. If the workout is ready, transitions to a loaded state; otherwise, begins a retry sequence.
        case checkSummary

        /// Called when the workout summary has been successfully loaded.
        case summaryLoaded(WorkoutSummary)

        /// Sets the training plan associated with this session. Called by `SessionFeature` on appear.
        case setTrainingSession(TrainingSession?)

        /// Watch confirmed that `finishWorkout()` succeeded. Transitions from `.saving` to `.loading`
        /// and begins polling HealthKit for the workout data.
        case workoutSavedReceived

        /// Timeout fired — Watch did not send `.workoutSaved` in time. Fall back to polling.
        case workoutSavedTimeout

        /// Result of the discard operation. `errorMessage == nil` → success (dismiss).
        /// Non-nil → real HK error (NOT idempotent noData) → show errorAlert + clear isDiscarding.
        case discardCompleted(errorMessage: String?)

        /// Receives HR samples and phase timestamps from the parent (SessionFeature)
        /// so that per-phase HR can be calculated at save time.
        case setHRData(hrBuffer: [(date: Date, bpm: Double)], phaseTimestamps: [(name: String, start: Date, end: Date?)])

        // MARK: - View Actions

        case view(View)

        @CasePathable
        enum View {

            /// Action triggered when the view appears on the screen.
            case viewDidAppear

            ///
            case viewDidDisappear

            ///
            case endWorkoutButtonTapped

            /// Dismisses the summary screen from the failed state.
            case closeButtonTapped

            /// Shows the discard confirmation alert.
            case discardWorkoutButtonTapped

            /// Toggles the visibility of the entire result section for the given WOD index.
            case toggleResult(Int)

            /// Toggles the note input visibility for the given WOD index.
            case toggleNote(Int)

            /// Updates the score text for the given WOD index.
            case updateScore(Int, String)

            /// Updates the note text for the given WOD index.
            case updateNote(Int, String)

            /// Opens the set input sheet for a specific exercise.
            case openSetInput(wodIndex: Int, exerciseIndex: Int)

            /// Updates the actual weight text for a specific exercise within a WOD.
            case updateExerciseWeight(wodIndex: Int, exerciseIndex: Int, String)

            /// Updates the actual reps text for a specific exercise within a WOD.
            case updateExerciseReps(wodIndex: Int, exerciseIndex: Int, String)

            /// Updates the scaling type for a specific exercise within a WOD.
            case updateExerciseScaling(wodIndex: Int, exerciseIndex: Int, ScalingType)

            /// Toggles the PR flag for a specific exercise within a WOD.
            case toggleExercisePR(wodIndex: Int, exerciseIndex: Int)
        }

        // MARK: - Set Input

        case setInput(PresentationAction<SetInputFeature.Action>)

        // MARK: - Alerts

        case alert(PresentationAction<DiscardAlert>)

        @CasePathable
        enum DiscardAlert {

            ///
            case confirmDiscard
        }

        /// Presentation action for the informational error alert (no actions — only dismiss).
        case errorAlert(PresentationAction<Never>)
    }

}

