//
//  SummaryFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import SharedModels

extension SummaryFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Current loading/display state of the summary screen.
        var viewState: SummaryState = .saving

        /// HealthKit workout data loaded after the session ends.
        var summary: WorkoutSummary? = nil

        /// The training plan that was executed, if any.
        /// `nil` for free workouts (no plan selected).
        var trainingSession: TrainingSession? = nil

        /// Editable WOD results — one per workout in the plan.
        /// Built from `trainingSession.workouts` when the plan is set.
        var resultInputs: [WorkoutSessionResult] = []

        /// UI flags — whether the result section is expanded per WOD index.
        var showResults: [Bool] = []

        /// UI flags — whether note input is expanded per WOD index.
        var showNotes: [Bool] = []

        /// Counts how many times checkSummary has been attempted (for debug logging).
        var summaryRetryCount: Int = 0

        /// Debug-only context string populated on failure (e.g. workout mode, last result).
        var failureDebugInfo: String = ""

        // MARK: - Alert

        /// Confirmation alert before discarding workout from HealthKit.
        @Presents var discardAlert: AlertState<Action.DiscardAlert>?
    }

}
