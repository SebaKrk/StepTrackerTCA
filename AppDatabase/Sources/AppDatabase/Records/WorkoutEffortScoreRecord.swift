//
//  WorkoutEffortScoreRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for the effort points of a single personal workout (IOS-00099).
///
/// **Frozen per-workout**: points are frozen from the live on-device accumulator
/// at workout end (never computed from HealthKit) and never rewritten by a weights
/// rebalance — `weightsVersion` records which table produced them.
///
/// Storage strategy: flat scalar columns (no BLOBs) — per-zone seconds live in
/// five REAL columns so SQL can aggregate them (monthly sums, time in Zone 4+).
@Table
public struct WorkoutEffortScoreRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public var id: UUID

    /// Reference to HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public var hkWorkoutId: UUID

    /// Total effort points (unbounded).
    public var points: Int

    /// Workout start date, denormalized from `HKWorkout.startDate` — indexed
    /// for period aggregates (monthly sum) without touching HealthKit.
    public var workoutStartDate: Date

    /// Seconds spent in each training zone at computation time.
    public var secondsZone1: Double
    public var secondsZone2: Double
    public var secondsZone3: Double
    public var secondsZone4: Double
    public var secondsZone5: Double

    /// `EffortPointsScoring.currentWeightsVersion` used for this computation.
    public var weightsVersion: Int

    // MARK: - CloudKitSyncable

    /// Timestamp of record creation.
    public var createdAt: Date

    /// Timestamp of last update — used for conflict resolution during iCloud sync.
    public var updatedAt: Date

    /// Encoded CKRecord system fields — nil until first CloudKit sync.
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        points: Int,
        workoutStartDate: Date,
        secondsZone1: Double,
        secondsZone2: Double,
        secondsZone3: Double,
        secondsZone4: Double,
        secondsZone5: Double,
        weightsVersion: Int,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.points = points
        self.workoutStartDate = workoutStartDate
        self.secondsZone1 = secondsZone1
        self.secondsZone2 = secondsZone2
        self.secondsZone3 = secondsZone3
        self.secondsZone4 = secondsZone4
        self.secondsZone5 = secondsZone5
        self.weightsVersion = weightsVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension WorkoutEffortScoreRecord {

    public init(from score: WorkoutEffortScore, createdAt: Date, updatedAt: Date) {
        self.init(
            id: score.id,
            hkWorkoutId: score.hkWorkoutId,
            points: score.points,
            workoutStartDate: score.workoutStartDate,
            secondsZone1: score.secondsByZone[.recovery] ?? 0,
            secondsZone2: score.secondsByZone[.fatBurning] ?? 0,
            secondsZone3: score.secondsByZone[.aerobic] ?? 0,
            secondsZone4: score.secondsByZone[.threshold] ?? 0,
            secondsZone5: score.secondsByZone[.anaerobic] ?? 0,
            weightsVersion: score.weightsVersion,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() -> WorkoutEffortScore {
        WorkoutEffortScore(
            id: id,
            hkWorkoutId: hkWorkoutId,
            points: points,
            workoutStartDate: workoutStartDate,
            secondsByZone: [
                .recovery: secondsZone1,
                .fatBurning: secondsZone2,
                .aerobic: secondsZone3,
                .threshold: secondsZone4,
                .anaerobic: secondsZone5,
            ],
            weightsVersion: weightsVersion
        )
    }
}
