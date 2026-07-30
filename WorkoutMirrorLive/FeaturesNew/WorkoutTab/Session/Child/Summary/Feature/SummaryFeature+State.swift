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
        var viewState: SummaryState = .loading

        /// HealthKit workout data loaded after the session ends.
        var summary: WorkoutSummary? = nil

        /// The training plan that was executed, if any.
        /// `nil` for free workouts (no plan selected).
        var trainingSession: TrainingSession? = nil

        /// Portable "Wyniki" section — per-WOD scoring cards. Embedded here
        /// editable; ActivityDetails embeds the same feature read-only.
        var results: WorkoutResultsFeature.State = .init()

        /// Counts how many times checkSummary has been attempted (for debug logging).
        var summaryRetryCount: Int = 0

        /// Debug-only context string populated on failure (e.g. workout mode, last result).
        var failureDebugInfo: String = ""

        // MARK: - HR Data (passed by parent)

        /// HR samples from the workout — passed by parent for per-phase HR calculation.
        var hrBuffer: [(date: Date, bpm: Double)] = []

        /// Per-minute HR ranges for the minute chart — computed ONCE when the
        /// buffer arrives (not per render; the buffer can hold hours of samples).
        var hrMinuteRanges: [HRMinuteRange] = []

        /// Minute selected by scrubbing the HR chart (selection state must live
        /// here — views hold no @State).
        var selectedChartMinute: Date?

        /// True once the user scrolls to the bottom — reveals the floating save bar.
        var isSaveButtonVisible: Bool = false

        /// Phase timestamps — passed by parent for per-phase HR calculation.
        var phaseTimestamps: [(name: String, start: Date, end: Date?)] = []

        /// Effort points earned this workout (Myzone-style), passed by the parent
        /// from the live accumulator at session end. `nil` in manual-entry mode
        /// (no live workout) → the card is hidden.
        var effortPoints: Int?

        /// Time spent in each HR zone, forwarded from the live accumulator at
        /// session end (or reconstructed in manual-entry mode). Drives the zones
        /// section and the screen accent. Empty ⇒ no zones card, mint fallback accent.
        var secondsByZone: [HeartRateZone: TimeInterval] = [:]

        /// User's maximum heart rate (age/HealthKit based) — zone classification
        /// and minute-chart colors need the USER max, not the session peak
        /// (`maxHeartRate` below). Fetched once via `maxHeartRateClient`.
        var userMaxHeartRate: Double?

        /// Dominant TRAINING zone by dwell time — resting is excluded so a
        /// mostly-idle session still accents by the hardest meaningful zone.
        /// `nil` when there is no zone data.
        var dominantZone: HeartRateZone? {
            secondsByZone
                .filter { $0.key != .resting }
                .max { $0.value < $1.value }?
                .key
        }

        /// Peak heart rate, derived from the collected samples. `WorkoutMetrics`
        /// has no max field — only `heartRate` (current, 0 once the workout ends) —
        /// so the max card must come from here, not from `metrics`.
        var maxHeartRate: Int {
            hrBuffer.map(\.bpm).max().map { Int($0.rounded()) } ?? 0
        }

        // MARK: - Discard

        /// True while delete operation is in flight. Drives Discard button → ProgressView swap.
        /// Guards against double-tap and gives user visual feedback during ~300ms re-fetch + delete.
        var isDiscarding: Bool = false

        /// True when SummaryFeature is opened via **manual entry** from History (Podpnij plan / Edytuj wynik).
        /// The workout has existed in HealthKit for a long time — Discard button = disaster (deletes the HKWorkout).
        /// This flag hides Discard from the toolbar + the reducer's `.viewDidAppear` skips polling/timeout.
        /// Set by the `manualEntry(...)` factory, false for the Watch-primary happy path.
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

    /// Manual entry factory — used from `ActivityDetailsFeature` when the user re-attaches a plan
    /// to an existing HKWorkout (after IOS-00098-E this is the main path for entering results
    /// for watch-primary workouts — from History, via the "Uzupełnij wyniki" badge).
    /// Builds a pre-filled State: `summary` + `trainingSession` + `hrBuffer`, sets
    /// `viewState = .successfullyLoaded`. The reducer in `.viewDidAppear` sees the pre-filled state
    /// and skips the poll/timeout.
    ///
    /// Static factory (not an init) — so it does NOT block the auto-generated member-wise init
    /// (`SummaryFeature.State(viewState:)`) used in previews and the happy path
    /// (`SessionFeature.State.summary = .init()`).
    ///
    /// **`existingResults`**:
    /// - `nil` (link-new flow) → `.viewDidAppear` maps fresh `resultInputs` from the template
    ///   (empty results to fill in).
    /// - non-nil (edit flow) → the factory sets `resultInputs` to the saved results, `.viewDidAppear`
    ///   skips the remapping. The user sees the UI with filled-in fields and can edit them.
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
        state.hrMinuteRanges = HRMinuteRange.from(buffer: hrBuffer)
        state.phaseTimestamps = phaseTimestamps
        state.viewState = .successfullyLoaded
        state.isManualEntry = true
        if let existingResults {
            state.results = .editable(
                trainingSession: trainingSession,
                existingResults: existingResults
            )
        }
        return state
    }
}
