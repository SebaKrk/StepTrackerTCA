//
//  SetEntry.swift
//  SharedModels
//

import Foundation

/// A single set within a strength or multi-set exercise.
///
/// Used when the weight changes between sets (e.g. Strength 5×5 with progressive loading).
/// For WOD exercises where weight is constant across rounds, `ExerciseLogInput` uses
/// `actualWeight`/`actualReps` directly — `sets` stays `nil`.
///
/// ## Example: Back Squat 5×5
/// ```
/// [
///     SetEntry(reps: 5, weight: 80),   // warm-up sets
///     SetEntry(reps: 5, weight: 80),
///     SetEntry(reps: 5, weight: 90),   // working sets
///     SetEntry(reps: 5, weight: 90),
///     SetEntry(reps: 5, weight: 100),  // PR set
/// ]
/// ```
///
/// ## Example: Shoulder Press 3×8 (failed last set)
/// ```
/// [
///     SetEntry(reps: 8, weight: 40),
///     SetEntry(reps: 8, weight: 40),
///     SetEntry(reps: 6, weight: 40),   // didn't finish — 6 instead of 8
/// ]
/// ```
public struct SetEntry: Identifiable, Equatable, Codable, Sendable {

    /// Unique identifier for this set.
    public var id: UUID

    /// Number of repetitions completed in this set.
    public var reps: Int

    /// Weight used in this set (kg). `nil` for bodyweight sets.
    public var weight: Double?

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        reps: Int = 0,
        weight: Double? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
    }
}
