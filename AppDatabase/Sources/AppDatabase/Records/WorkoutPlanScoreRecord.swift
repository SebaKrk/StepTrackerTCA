//
//  WorkoutPlanScoreRecord.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 22/03/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for a completed training session result.
///
/// Links a `TrainingSession` plan with an `HKWorkout` health record
/// and stores WOD results as a JSON-encoded BLOB.
///
/// Storage strategy:
/// - Scalar fields (id, date, trainingSessionId, hkWorkoutId) → flat TEXT columns
/// - `results: [WorkoutSessionResult]` → JSON-encoded BLOB
@Table
public struct WorkoutPlanScoreRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync
    public var id: UUID

    /// Date of execution — snapshot independent of HKWorkout
    public var date: Date

    /// Reference to the source `TrainingSession` plan
    public var trainingSessionId: UUID

    /// Reference to the corresponding `HKWorkout` in HealthKit
    public var hkWorkoutId: UUID

    /// JSON-encoded [WorkoutSessionResult] — WOD results for this execution
    public var resultsData: Data

    // MARK: - CloudKitSyncable

    /// Timestamp of record creation
    public var createdAt: Date

    /// Timestamp of last update — used for conflict resolution during iCloud sync
    public var updatedAt: Date

    /// Encoded CKRecord system fields (zone ID, record name, changeTag) — nil until first CloudKit sync
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        date: Date,
        trainingSessionId: UUID,
        hkWorkoutId: UUID,
        resultsData: Data,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.trainingSessionId = trainingSessionId
        self.hkWorkoutId = hkWorkoutId
        self.resultsData = resultsData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension WorkoutPlanScoreRecord {

    public init(from score: WorkoutPlanScore, createdAt: Date, updatedAt: Date) throws {
        let encoder = JSONEncoder()
        self.init(
            id: score.id,
            date: score.date,
            trainingSessionId: score.trainingSessionId,
            hkWorkoutId: score.hkWorkoutId,
            resultsData: try encoder.encode(score.results),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() throws -> WorkoutPlanScore {
        let decoder = JSONDecoder()
        return WorkoutPlanScore(
            id: id,
            date: date,
            trainingSessionId: trainingSessionId,
            hkWorkoutId: hkWorkoutId,
            results: try decoder.decode([WorkoutSessionResult].self, from: resultsData)
        )
    }
}
