//
//  ExerciseLogRecord.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for a single exercise instance from a completed workout.
///
/// All fields are flat columns (no BLOBs) — every value is directly queryable.
///
/// Storage strategy:
/// - Enums (`exerciseType`, `category`, `scaling`) → stored as String rawValue
/// - `isPR` → INTEGER (Bool)
/// - Dates → TEXT (ISO 8601 via SQLiteData)
@Table
public struct ExerciseLogRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync
    public var id: UUID

    /// Date of execution
    public var date: Date

    // Exercise identity

    /// ExerciseType rawValue — nil when exercise is unmatched
    public var exerciseType: String?

    /// Free-text name when no ExerciseType match was found
    public var unmatchedName: String?

    /// MovementCategory rawValue
    public var category: String?

    // Training context

    /// Reference to the parent WorkoutPlanScore
    public var workoutPlanScoreId: UUID?

    /// Name of the WOD this exercise belongs to
    public var wodName: String?

    // Plan (pre-fill)

    /// Prescribed reps (e.g. "5-5-5-5-5", "21-15-9")
    public var plannedReps: String?

    /// Prescribed weight in kg
    public var plannedWeight: Double?

    // Actual

    /// Actual weight used in kg
    public var actualWeight: Double?

    /// Actual reps performed
    public var actualReps: String?

    /// ScalingType rawValue — rx / scaled / rxPlus
    public var scaling: String

    /// Whether this was a personal record
    public var isPR: Bool

    // HR per phase

    /// Average heart rate during this exercise phase
    public var avgHeartRate: Double?

    /// Maximum heart rate during this exercise phase
    public var maxHeartRate: Double?

    /// Start of the exercise phase
    public var phaseStartDate: Date?

    /// End of the exercise phase
    public var phaseEndDate: Date?

    /// Duration in seconds of the exercise phase
    public var timeInPhase: Double?

    // Computed at save time

    /// Total volume load (weight x reps)
    public var volumeLoad: Double?

    /// Average tempo per round in seconds
    public var tempoPerRound: Double?

    /// Free-text note
    public var note: String?

    /// Deadline after which the log is locked
    public var editableUntil: Date?

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
        exerciseType: String?,
        unmatchedName: String?,
        category: String?,
        workoutPlanScoreId: UUID?,
        wodName: String?,
        plannedReps: String?,
        plannedWeight: Double?,
        actualWeight: Double?,
        actualReps: String?,
        scaling: String,
        isPR: Bool,
        avgHeartRate: Double?,
        maxHeartRate: Double?,
        phaseStartDate: Date?,
        phaseEndDate: Date?,
        timeInPhase: Double?,
        volumeLoad: Double?,
        tempoPerRound: Double?,
        note: String?,
        editableUntil: Date?,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.exerciseType = exerciseType
        self.unmatchedName = unmatchedName
        self.category = category
        self.workoutPlanScoreId = workoutPlanScoreId
        self.wodName = wodName
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.actualWeight = actualWeight
        self.actualReps = actualReps
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension ExerciseLogRecord {

    public init(from log: ExerciseLog, createdAt: Date, updatedAt: Date) {
        self.init(
            id: log.id,
            date: log.date,
            exerciseType: log.exerciseType?.rawValue,
            unmatchedName: log.unmatchedName,
            category: log.category?.rawValue,
            workoutPlanScoreId: log.workoutPlanScoreId,
            wodName: log.wodName,
            plannedReps: log.plannedReps,
            plannedWeight: log.plannedWeight,
            actualWeight: log.actualWeight,
            actualReps: log.actualReps,
            scaling: log.scaling.rawValue,
            isPR: log.isPR,
            avgHeartRate: log.avgHeartRate,
            maxHeartRate: log.maxHeartRate,
            phaseStartDate: log.phaseStartDate,
            phaseEndDate: log.phaseEndDate,
            timeInPhase: log.timeInPhase,
            volumeLoad: log.volumeLoad,
            tempoPerRound: log.tempoPerRound,
            note: log.note,
            editableUntil: log.editableUntil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() -> ExerciseLog {
        ExerciseLog(
            id: id,
            date: date,
            exerciseType: exerciseType.flatMap { ExerciseType(rawValue: $0) },
            unmatchedName: unmatchedName,
            category: category.flatMap { MovementCategory(rawValue: $0) },
            workoutPlanScoreId: workoutPlanScoreId,
            wodName: wodName,
            plannedReps: plannedReps,
            plannedWeight: plannedWeight,
            actualWeight: actualWeight,
            actualReps: actualReps,
            scaling: ScalingType(rawValue: scaling) ?? .rx,
            isPR: isPR,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            phaseStartDate: phaseStartDate,
            phaseEndDate: phaseEndDate,
            timeInPhase: timeInPhase,
            volumeLoad: volumeLoad,
            tempoPerRound: tempoPerRound,
            note: note,
            editableUntil: editableUntil
        )
    }
}
