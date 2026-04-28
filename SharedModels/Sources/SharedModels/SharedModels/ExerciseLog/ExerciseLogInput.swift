//
//  ExerciseLogInput.swift
//  SharedModels
//

import Foundation

/// User's input for a single exercise collected on the Summary screen after a workout.
///
/// Pre-filled from the training plan (`ExerciseSession`), the user optionally edits
/// actual values (weight, reps, scaling, PR).
///
/// At save time, `ExerciseLogInput` is combined with HR data from
/// `LiveSessionFeature.hrBuffer` to produce the final `ExerciseLog` row in SQL.
///
/// ## Fields
/// - **Planned values** (`plannedReps`, `plannedWeight`): read-only snapshot copied from
///   `ExerciseSession` at creation time. Displayed on Summary screen so the user knows
///   what was prescribed. Not editable by the user.
/// - **Actual values** (`actualWeight`, `actualReps`): pre-filled from planned, user edits
///   if they scaled or didn't complete the scheme.
///
/// ## Input modes
/// - **Simple** (AMRAP, FOR TIME, EMOM): `actualWeight` + `actualReps` — one weight for the whole exercise.
///   `sets` is `nil`.
/// - **Per-set** (Strength, Olympic): `sets: [SetEntry]` — weight and reps per set.
///   When `sets` is populated, it overrides `actualWeight`/`actualReps` for calculations.
///
/// ## Example: FOR TIME (simple)
/// ```
/// ExerciseLogInput(exerciseType: .thrusters, plannedWeight: 43, actualWeight: 43, actualReps: "21-15-9")
/// ```
///
/// ## Example: Strength 5×5 (per-set)
/// ```
/// ExerciseLogInput(exerciseType: .backSquat, plannedReps: "5-5-5-5-5", sets: [
///     SetEntry(reps: 5, weight: 80),
///     SetEntry(reps: 5, weight: 80),
///     SetEntry(reps: 5, weight: 90),
///     SetEntry(reps: 5, weight: 90),
///     SetEntry(reps: 5, weight: 100),  // PR set
/// ])
/// ```
public struct ExerciseLogInput: Equatable, Codable, Sendable, Identifiable {

    /// Unique identifier for this input entry.
    public var id: UUID

    /// Known exercise type from the catalog. `nil` when the exercise was not matched.
    public var exerciseType: ExerciseType?

    /// Original name from OCR/AI when `exerciseType` is `nil` (unmatched exercise).
    public var unmatchedName: String?

    /// Movement category (strength, olympicLifting, gymnastics, cardio, mixed).
    /// Derived from `exerciseType.category` when matched, `nil` when unmatched.
    public var category: MovementCategory?

    // MARK: - Planned (read-only snapshot from ExerciseSession)

    /// Target from the training plan — defines the unit and value (reps, meters, calories, etc.).
    /// Read-only — used to determine input field type and placeholder on Summary screen.
    public var target: ExerciseTarget?

    /// Reps/scheme from the training plan. Read-only — displayed as context on Summary screen.
    /// Examples: "21-15-9", "5-5-5-5-5", "15 cal".
    public var plannedReps: String?

    /// Prescribed weight from the training plan (auto-selected by biological sex).
    /// Read-only — displayed as context on Summary screen. `nil` for bodyweight exercises.
    public var plannedWeight: Double?

    // MARK: - Actual — Simple (AMRAP, FOR TIME, EMOM)

    /// Weight the user actually used. Pre-filled from `plannedWeight`, user edits if scaled.
    /// `nil` for bodyweight exercises. Used when `sets` is `nil`.
    public var actualWeight: Double?

    /// Reps/scheme the user actually completed. Pre-filled from `plannedReps`.
    /// Examples: "21-15-9", "50", "8-8-6". Used when `sets` is `nil`.
    public var actualReps: String?

    // MARK: - Actual — Per-Set (Strength, Olympic)

    /// Per-set detail when weight varies between sets (e.g. progressive loading).
    /// When populated, overrides `actualWeight`/`actualReps` for volume and PR calculations.
    /// `nil` for WOD exercises where weight is constant.
    ///
    /// Pre-filled by reducer: parses `plannedReps` ("5-5-5-5-5" → 5 entries)
    /// or uses WOD `rounds` count. User fills in weight per set.
    public var sets: [SetEntry]?

    // MARK: - Metadata

    /// How the user performed relative to prescribed: Rx, Scaled, or Rx+.
    public var scaling: ScalingType

    /// Whether this exercise was a personal record.
    public var isPR: Bool

    /// Optional note for this specific exercise.
    public var note: String

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        exerciseType: ExerciseType? = nil,
        unmatchedName: String? = nil,
        category: MovementCategory? = nil,
        target: ExerciseTarget? = nil,
        plannedReps: String? = nil,
        plannedWeight: Double? = nil,
        actualWeight: Double? = nil,
        actualReps: String? = nil,
        sets: [SetEntry]? = nil,
        scaling: ScalingType = .rx,
        isPR: Bool = false,
        note: String = ""
    ) {
        self.id = id
        self.exerciseType = exerciseType
        self.unmatchedName = unmatchedName
        self.category = category
        self.target = target
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.actualWeight = actualWeight
        self.actualReps = actualReps
        self.sets = sets
        self.scaling = scaling
        self.isPR = isPR
        self.note = note
    }
}
