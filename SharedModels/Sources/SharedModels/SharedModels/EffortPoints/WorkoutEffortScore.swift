//
//  WorkoutEffortScore.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import Foundation

/// Persisted effort points for a single personal workout — the value FROZEN from
/// the live on-device accumulator at workout end (see `PendingEffortScore`). It is
/// never recomputed from HealthKit and never recalculated for historical workouts
/// ("a result is a result").
///
/// **Frozen**: once stored, points are never rewritten by a weights rebalance —
/// `weightsVersion` records which table produced them. The per-zone seconds
/// breakdown is kept so future stats (monthly charts, "time in Zone 4+") and the
/// per-zone points display can be derived without re-fetching HealthKit — NOT to
/// recompute the total (which stays frozen).
public struct WorkoutEffortScore: Identifiable, Equatable, Codable, Sendable {

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public let id: UUID

    /// Reference to HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public let hkWorkoutId: UUID

    /// Total effort points (unbounded — a hard hour lands in the hundreds).
    public let points: Int

    /// Workout start date, denormalized from `HKWorkout.startDate` — enables
    /// pure-SQL period aggregates (monthly sum) without touching HealthKit.
    public let workoutStartDate: Date

    /// Seconds spent in each training zone at computation time.
    public let secondsByZone: [HeartRateZone: TimeInterval]

    /// `EffortPointsScoring.currentWeightsVersion` used for this computation.
    public let weightsVersion: Int

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        points: Int,
        workoutStartDate: Date,
        secondsByZone: [HeartRateZone: TimeInterval],
        weightsVersion: Int
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.points = points
        self.workoutStartDate = workoutStartDate
        self.secondsByZone = secondsByZone
        self.weightsVersion = weightsVersion
    }
}
