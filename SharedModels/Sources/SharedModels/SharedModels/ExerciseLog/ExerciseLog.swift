//
//  ExerciseLog.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import Foundation

/// A single exercise instance from a completed workout — one row per exercise per WOD.
public struct ExerciseLog: Identifiable, Equatable, Codable, Sendable {

    /// Stable identifier — never changes after the log is created.
    /// Used by editors to round-trip edits back to the same SQLite row.
    public var id: UUID
    /// Wall-clock time the log was first recorded (= workout completion time).
    /// Mirrors the parent `WorkoutPlanScore.date` for logs created from a session.
    public var date: Date

    // MARK: - Exercise identity

    /// Catalog exercise resolved from the plan text via AI / alias matching.
    /// `nil` for unmatched / custom entries — fall back to `unmatchedName` for display.
    public var exerciseType: ExerciseType?
    /// Display name used when `exerciseType` is `nil` (OCR / AI couldn't match a catalog entry).
    /// Surfaced verbatim in the UI; presence indicates an "unknown" exercise.
    public var unmatchedName: String?
    /// Movement category (Strength, OlympicLifting, Gymnastics, Cardio, Mixed).
    /// Drives icon / color coding, set-input prompts, and analytics grouping.
    /// Derived from `exerciseType.category` at save time; `nil` only for unmatched entries.
    public var category: MovementCategory?

    // MARK: - Training context

    /// Reference to the parent `WorkoutPlanScore` (one per training session, shared across all logs from that session).
    /// Foreign key into `WorkoutPlanScoreRecord`; used for "give me all logs from this training" queries.
    public var workoutPlanScoreId: UUID?
    /// Unique reference to the parent `WorkoutSessionResult` within a `WorkoutPlanScore`.
    ///
    /// One `WorkoutPlanScore` is persisted per training session and carries
    /// `results: [WorkoutSessionResult]` — every workout from that session.
    /// Because all exercise logs from a single training share the same
    /// `workoutPlanScoreId`, filtering by score id alone returns logs from
    /// *all* workouts mixed together.
    ///
    /// This field disambiguates that: every log stores the `id` of the specific
    /// `WorkoutSessionResult` it belongs to, allowing per-workout filtering even
    /// when multiple workouts in one session share the same `wodName`
    /// (e.g. several "Strength" workouts produced by the AI plan parser).
    ///
    /// Nullable to preserve compatibility with legacy logs persisted before this
    /// field existed — those callers fall back to filtering by `wodName`.
    public var workoutSessionResultId: UUID?
    /// Free-text workout name (display label, e.g. "Strength", "WOD 1").
    /// Not unique within a training session — use `workoutSessionResultId` for
    /// precise per-workout filtering.
    public var wodName: String?

    // MARK: - Plan (pre-fill from AI scan)

    /// Reps as written in the plan (free-text — can be "5", "10-15", "AMRAP", "15 cal").
    /// Used as TextField placeholder in SetInputView so the user sees the prescribed value.
    /// Not parsed into structured form — keep as string for human-readable display.
    public var plannedReps: String?
    /// Prescribed weight in kg, when the plan specifies one (e.g. `"@ 80kg"`).
    /// `nil` for percent-based prescriptions (`"@ 50-60%"`) and bodyweight exercises.
    /// Drives the "Plan: X kg" hint shown under each exercise in SetInputView.
    public var plannedWeight: Double?

    // MARK: - Actual (entered by user post-workout)

    /// User-entered weight for the exercise. For per-set workouts mirrors `sets.compactMap(\.weight).max()`
    /// so legacy summaries (Activity tabs, analytics) keep working with a single value.
    /// For simple WOD entries this is the single weight the user typed once.
    public var actualWeight: Double?
    /// User-entered reps as a free-text string. For per-set workouts mirrors the
    /// joined `"5-5-5-5-5"` summary built from `sets`. For simple WOD entries this
    /// is whatever the user typed (e.g. `"21-15-9"`, `"15"`, `"AMRAP"`).
    public var actualReps: String?
    /// Per-set breakdown captured by SetInputView for strength/olympic workouts.
    ///
    /// When present, the Activity Details screen renders a per-set table
    /// (Set | Reps | kg) preserving the exact reps and weight entered for each set.
    /// `actualWeight` mirrors the max set weight for legacy single-value displays;
    /// `actualReps` mirrors a joined `"5-5-5-5-5"` summary. Nil for non-strength
    /// workouts (AMRAP/forTime/EMOM) where the simpler single-row table is used.
    public var sets: [SetEntry]?
    /// Scaling tier the user trained at (Rx / Scaled / Bodyweight).
    /// Drives PR comparisons (`isPR` is only valid within same scaling tier) and analytics filtering.
    public var scaling: ScalingType
    /// Personal Record flag set during save when this entry beats the user's
    /// previous best for the same `exerciseType` + `scaling` combination.
    /// Surfaced as the orange "PR" badge in Activity Details and analytics.
    public var isPR: Bool

    // MARK: - Heart rate (per exercise phase)

    /// Average HR (bpm) during the phase this exercise was performed, sampled from HealthKit.
    /// `nil` when no HR samples fell within `phaseStartDate...phaseEndDate`
    /// (e.g. watch off, exercise too short for sampling).
    public var avgHeartRate: Double?
    /// Peak HR (bpm) recorded during the phase. Used for intensity badges and HR-zone analytics.
    public var maxHeartRate: Double?
    /// Phase boundary — when the user started this exercise during the workout.
    /// Captured by the watch-side phase tracker; `nil` when phase timestamps weren't available.
    public var phaseStartDate: Date?
    /// Phase boundary — when the user finished this exercise. Combined with `phaseStartDate`
    /// to compute `timeInPhase` and to filter HR samples for `avgHeartRate` / `maxHeartRate`.
    public var phaseEndDate: Date?
    /// Duration of the exercise phase in seconds (`phaseEndDate - phaseStartDate`).
    /// Computed at save time so analytics can read it without re-deriving.
    public var timeInPhase: Double?

    // MARK: - Computed at save time

    /// Total work performed for this exercise: `totalReps × actualWeight` (kg·reps).
    /// Powers the "Volume per Week" chart and other strength analytics. `nil` for
    /// bodyweight / cardio exercises where the metric doesn't apply.
    public var volumeLoad: Double?
    /// Average time per round/rep in seconds, computed from workout score for For-Time WODs.
    /// Empty for strength / AMRAP — useful only when pace per round is meaningful.
    public var tempoPerRound: Double?

    /// Free-text note the user typed in SetInputView ("forma się sypała", "PR!", etc.).
    /// Rendered verbatim under the exercise row in Activity Details.
    public var note: String?
    /// Hard cutoff after which the log becomes read-only (~72h post-workout).
    /// Stops users from rewriting history once analytics have processed the data.
    /// `nil` for legacy logs created before the edit-window feature shipped.
    public var editableUntil: Date?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseType: ExerciseType? = nil,
        unmatchedName: String? = nil,
        category: MovementCategory? = nil,
        workoutPlanScoreId: UUID? = nil,
        workoutSessionResultId: UUID? = nil,
        wodName: String? = nil,
        plannedReps: String? = nil,
        plannedWeight: Double? = nil,
        actualWeight: Double? = nil,
        actualReps: String? = nil,
        sets: [SetEntry]? = nil,
        scaling: ScalingType = .rx,
        isPR: Bool = false,
        avgHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        phaseStartDate: Date? = nil,
        phaseEndDate: Date? = nil,
        timeInPhase: Double? = nil,
        volumeLoad: Double? = nil,
        tempoPerRound: Double? = nil,
        note: String? = nil,
        editableUntil: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.exerciseType = exerciseType
        self.unmatchedName = unmatchedName
        self.category = category
        self.workoutPlanScoreId = workoutPlanScoreId
        self.workoutSessionResultId = workoutSessionResultId
        self.wodName = wodName
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.sets = sets
        self.scaling = scaling
        self.isPR = isPR
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.phaseStartDate = phaseStartDate
        self.phaseEndDate = phaseEndDate
        self.timeInPhase = timeInPhase
        self.volumeLoad = volumeLoad
        self.tempoPerRound = tempoPerRound
        self.note = note
        self.editableUntil = editableUntil
    }

    /// Whether this log is still within the post-workout edit window.
    /// Returns `false` for legacy logs (no `editableUntil` set) and for any log
    /// whose window has already expired.
    public func isEditable(now: Date) -> Bool {
        guard let editableUntil else { return false }
        return editableUntil > now
    }
}
