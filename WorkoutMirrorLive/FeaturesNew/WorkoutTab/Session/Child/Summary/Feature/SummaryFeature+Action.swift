//
//  SummaryFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
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
        }

        // MARK: - Alert

        case alert(PresentationAction<DiscardAlert>)

        @CasePathable
        enum DiscardAlert {
            
            ///
            case confirmDiscard
        }
    }

}

