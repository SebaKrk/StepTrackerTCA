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

        /// WOD scoring child features — jedno per workout w planie. Każdy element zarządza
        /// własnym `WorkoutSessionResult` (score, note, exercises) + UI toggle flags
        /// (showResults, showNotes, exercisesEdited).
        ///
        /// **Refactor IOS-00096-B**: zastępuje 4 paralelne arrays (`resultInputs` +
        /// `showResults` + `showNotes` + `exercisesEdited`) jednym `IdentifiedArrayOf` —
        /// eliminuje drift index'ów + cascading re-renders gdy zmienia się pojedyncze pole.
        var wodScorings: IdentifiedArrayOf<WODScoringFeature.State> = []

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

        /// True gdy SummaryFeature otwarty przez **manual entry** z History (Podpnij plan / Edytuj wynik).
        /// Workout już istnieje w HealthKit od dawna — Discard button = katastrofa (kasuje HKWorkout).
        /// Ten flag ukrywa Discard z toolbar'a + reducer'owi `.viewDidAppear` pomija polling/timeout.
        /// Ustawiany przez `manualEntry(...)` factory, false dla happy path Watch-primary.
        var isManualEntry: Bool = false

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
        state.isManualEntry = true
        if let existingResults {
            state.wodScorings = IdentifiedArrayOf(
                uniqueElements: existingResults.enumerated().map { index, result in
                    WODScoringFeature.State(wodIndex: index, result: result)
                }
            )
        }
        return state
    }
}
