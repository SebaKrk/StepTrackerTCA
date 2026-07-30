//
//  WorkoutPlanScore.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 03/03/2026.
//

import Foundation

/// A single execution of a training plan.
///
/// Links a `TrainingSession` (plan) with an `HKWorkout` (health data)
/// and stores the user's WOD results as an immutable snapshot.
///
/// Relationships:
/// - `TrainingSession` (1) → `WorkoutPlanScore` (many) — timeline of plan executions
/// - `WorkoutPlanScore` (1) → `HKWorkout` (1) — health data for this execution
///
/// Storage: CoreData + CloudKit (see IOS-00070-B2)
public struct WorkoutPlanScore: Identifiable, Equatable, Codable, Sendable {

    // MARK: - Properties

    /// Primary key — used for CoreData identity and upsert logic.
    public let id: UUID

    /// Date of execution — snapshot independent of HKWorkout.
    /// Survives even if the HKWorkout is deleted from Health.
    public let date: Date

    /// Reference to the source `TrainingSession` plan.
    public let trainingSessionId: UUID

    /// Reference to the corresponding `HKWorkout` in HealthKit.
    /// Indexed in CoreData for efficient lookup by workout UUID.
    public let hkWorkoutId: UUID

    /// WOD results for this execution — only WODs, no warmup/cooldown.
    /// Each entry contains a snapshot of the workout description at the time of execution.
    public var results: [WorkoutSessionResult]

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        trainingSessionId: UUID,
        hkWorkoutId: UUID,
        results: [WorkoutSessionResult]
    ) {
        self.id = id
        self.date = date
        self.trainingSessionId = trainingSessionId
        self.hkWorkoutId = hkWorkoutId
        self.results = results
    }
}
