//
//  SummaryFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 30/08/2025.
//

import ComposableArchitecture
import Foundation
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

        /// UI flags — whether exercises were edited via sheet per WOD index.
        var exercisesEdited: [Bool] = []

        /// Counts how many times checkSummary has been attempted (for debug logging).
        var summaryRetryCount: Int = 0

        /// Debug-only context string populated on failure (e.g. workout mode, last result).
        var failureDebugInfo: String = ""

        // MARK: - HR Data (passed by parent)

        /// HR samples from the workout — passed by parent for per-phase HR calculation.
        var hrBuffer: [(date: Date, bpm: Double)] = []

        /// Phase timestamps — passed by parent for per-phase HR calculation.
        var phaseTimestamps: [(name: String, start: Date, end: Date?)] = []

        // MARK: - Set Input Sheet

        /// Child feature for the per-set input sheet. `nil` = sheet not presented.
        @Presents var setInput: SetInputFeature.State?

        // MARK: - Discard

        /// True while delete operation is in flight. Drives Discard button → ProgressView swap.
        /// Guards against double-tap and gives user visual feedback during ~300ms re-fetch + delete.
        var isDiscarding: Bool = false

        // MARK: - Alerts

        /// Confirmation alert before discarding workout from HealthKit.
        @Presents var discardAlert: AlertState<Action.DiscardAlert>?

        /// Informational alert shown when HealthKit deletion fails for a real reason
        /// (not idempotent "already absent" — that is treated as success in SessionClient.deleteWorkout).
        @Presents var errorAlert: AlertState<Never>?
    }

}

extension SummaryFeature.State {

    /// Manual entry factory — używany z `ActivityDetailsFeature` gdy user re-attache'uje plan
    /// do istniejącego HKWorkout (escape hatch dla failed `.saving → .summary` flow).
    /// Buduje pre-filled State: `summary` + `trainingSession` + `hrBuffer`, ustawia
    /// `viewState = .successfullyLoaded`. Reducer w `.viewDidAppear` widzi pre-filled state
    /// i pomija poll/timeout.
    ///
    /// Static factory (nie init) — żeby NIE blokować auto-generated member-wise init'a
    /// (`SummaryFeature.State(viewState:)`) używanego w previews i happy path
    /// (`SessionFeature.State.summary = .init()`).
    ///
    /// **`existingResults`**:
    /// - `nil` (link-new flow) → `.viewDidAppear` zmapuje świeże `resultInputs` z template'a
    ///   (puste wyniki do wpisania).
    /// - non-nil (edit flow) → factory ustawia `resultInputs` na zapisane wyniki, `.viewDidAppear`
    ///   pomija remapping. User widzi UI z wypełnionymi polami i może je edytować.
    static func manualEntry(
        summary: WorkoutSummary,
        trainingSession: TrainingSession,
        hrBuffer: [(date: Date, bpm: Double)],
        phaseTimestamps: [(name: String, start: Date, end: Date?)] = [],
        existingResults: [WorkoutSessionResult]? = nil
    ) -> Self {
        var state = Self()
        state.summary = summary
        state.trainingSession = trainingSession
        state.hrBuffer = hrBuffer
        state.phaseTimestamps = phaseTimestamps
        state.viewState = .successfullyLoaded
        if let existingResults {
            state.resultInputs = existingResults
            let count = existingResults.count
            state.showResults = Array(repeating: false, count: count)
            state.showNotes = Array(repeating: false, count: count)
            state.exercisesEdited = Array(repeating: false, count: count)
        }
        return state
    }
}
