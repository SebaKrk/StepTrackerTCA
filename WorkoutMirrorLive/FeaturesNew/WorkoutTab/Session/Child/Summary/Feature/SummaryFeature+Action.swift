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

        /// Result of the discard operation. `errorMessage == nil` → success (dismiss).
        /// Non-nil → real HK error (NOT idempotent noData) → show errorAlert + clear isDiscarding.
        case discardCompleted(errorMessage: String?)

        /// Receives HR samples and phase timestamps from the parent (SessionFeature)
        /// so that per-phase HR can be calculated at save time.
        case setHRData(hrBuffer: [(date: Date, bpm: Double)], phaseTimestamps: [(name: String, start: Date, end: Date?)])

        /// Parent passes the live effort points total + full per-zone dwell times
        /// at session end. The zone dictionary drives the zones section and the
        /// screen accent (dominant zone is derived in State).
        case setEffortPoints(points: Int, secondsByZone: [HeartRateZone: TimeInterval])

        /// Result of the one-shot user max-HR fetch — needed to classify zones
        /// and color the minute chart (user max, not session peak).
        case setUserMaxHeartRate(Double)

        // MARK: - Delegate

        /// Messages to ancestors (AppTabNewFeature listens through the
        /// destination chain).
        case delegate(Delegate)

        enum Delegate: Equatable {

            /// iPhone-standalone: the summary confirmed the locally saved
            /// HKWorkout. The Watch never sends `.workoutSaved` in this mode,
            /// so this is the ONLY signal that can consume `PendingEffortScore`
            /// — without it a strap workout freezes its points into the pending
            /// file and the next session silently overwrites them.
            case savedWorkoutFound(UUID)
        }

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

            /// HR minute chart scrub — the selected minute (nil clears the selection).
            case chartMinuteSelected(Date?)

            /// Scroll reached (or left) the bottom — toggles the floating save bar.
            case saveButtonVisibilityChanged(Bool)
        }

        // MARK: - Results (portable child feature)

        /// Forwarded actions of the embedded "Wyniki" section (per-WOD cards live inside).
        case results(WorkoutResultsFeature.Action)

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

