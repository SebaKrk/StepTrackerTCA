//
//  WorkoutHRSnapshotRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record dla snapshot'u maksymalnego tętna pojedynczego workout'u (IOS-00097-F).
///
/// **Freeze per-workout**: gdy user zmieni formułę w Settings, historyczne workout'y które
/// już mają snapshot zachowują **starą** formułę. Tylko nowe workout'y używają current formula.
///
/// Storage strategy: flat scalar columns (brak BLOBs) — wszystkie pola są primitive types.
@Table
public struct WorkoutHRSnapshotRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public var id: UUID

    /// Reference do HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public var hkWorkoutId: UUID

    /// Frozen maxHR value w momencie snapshot creation.
    public var maxHR: Double

    /// `HRFormulaType.rawValue` (np. "tanaka", "nes", "gulati", "fairbarn", "classic").
    public var formulaRawValue: String

    /// Wiek user'a w momencie snapshot creation (lat).
    public var ageAtWorkout: Int

    /// `BiologicalSex.rawValue` (np. "male", "female", "notSet", "unknown").
    public var biologicalSexRawValue: String

    // MARK: - CloudKitSyncable

    /// Timestamp of record creation.
    public var createdAt: Date

    /// Timestamp of last update — używane do conflict resolution podczas iCloud sync.
    public var updatedAt: Date

    /// Encoded CKRecord system fields — nil dopóki pierwszej CloudKit sync.
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        maxHR: Double,
        formulaRawValue: String,
        ageAtWorkout: Int,
        biologicalSexRawValue: String,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.maxHR = maxHR
        self.formulaRawValue = formulaRawValue
        self.ageAtWorkout = ageAtWorkout
        self.biologicalSexRawValue = biologicalSexRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension WorkoutHRSnapshotRecord {

    public init(from snapshot: WorkoutHRSnapshot, createdAt: Date, updatedAt: Date) {
        self.init(
            id: snapshot.id,
            hkWorkoutId: snapshot.hkWorkoutId,
            maxHR: snapshot.maxHR,
            formulaRawValue: snapshot.formulaRawValue,
            ageAtWorkout: snapshot.ageAtWorkout,
            biologicalSexRawValue: snapshot.biologicalSex.rawValue,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() -> WorkoutHRSnapshot {
        WorkoutHRSnapshot(
            id: id,
            hkWorkoutId: hkWorkoutId,
            maxHR: maxHR,
            formulaRawValue: formulaRawValue,
            ageAtWorkout: ageAtWorkout,
            biologicalSex: BiologicalSex(rawValue: biologicalSexRawValue) ?? .unknown
        )
    }
}
