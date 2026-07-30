//
//  ClassParticipationRecord.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import Foundation
import SharedModels
import SQLiteData

// MARK: - Record

/// SQLite record for a participant's attendance of a GymRoom class (IOS-00104-C),
/// linked 1:1 to their workout via `hkWorkoutId`.
///
/// Separate table from `WorkoutEffortScoreRecord` on purpose: effort score only exists
/// when the workout earned points, but attendance shows even for a zero-point class.
/// Frozen at class end (recap from iPad + local gymName/classPoints) — never recomputed.
///
/// Storage strategy: flat scalar columns (no BLOB) so the recap section reads directly.
@Table
public struct ClassParticipationRecord: Identifiable, CloudKitSyncable {

    // MARK: - Properties

    /// Unique identifier — stable across updates, used for CloudKit sync.
    public var id: UUID

    /// Reference to HealthKit `HKWorkout.uuid` — primary lookup key (1:1 relationship).
    public var hkWorkoutId: UUID

    /// The class-session instance attended (links to `ClassSessionRecord.id`).
    public var classSessionId: UUID

    /// Class display name.
    public var gymName: String

    /// Finishing place in the class ranking (1-based).
    public var place: Int

    /// Total number of participants in the class.
    public var participantCount: Int

    /// Points earned within the class window (window-scoped).
    public var classPoints: Int

    /// Class location coordinates for the recap map — nil when no geocoded address.
    public var latitude: Double?
    public var longitude: Double?

    // MARK: - CloudKitSyncable

    public var createdAt: Date
    public var updatedAt: Date
    public var ckRecordData: Data?

    // MARK: - Init

    public init(
        id: UUID,
        hkWorkoutId: UUID,
        classSessionId: UUID,
        gymName: String,
        place: Int,
        participantCount: Int,
        classPoints: Int,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date,
        updatedAt: Date,
        ckRecordData: Data? = nil
    ) {
        self.id = id
        self.hkWorkoutId = hkWorkoutId
        self.classSessionId = classSessionId
        self.gymName = gymName
        self.place = place
        self.participantCount = participantCount
        self.classPoints = classPoints
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ckRecordData = ckRecordData
    }
}

// MARK: - Mapping

extension ClassParticipationRecord {

    public init(from participation: ClassParticipation, createdAt: Date, updatedAt: Date) {
        self.init(
            id: participation.id,
            hkWorkoutId: participation.hkWorkoutId,
            classSessionId: participation.classSessionId,
            gymName: participation.gymName,
            place: participation.place,
            participantCount: participation.participantCount,
            classPoints: participation.classPoints,
            latitude: participation.latitude,
            longitude: participation.longitude,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func toDomain() -> ClassParticipation {
        ClassParticipation(
            id: id,
            hkWorkoutId: hkWorkoutId,
            classSessionId: classSessionId,
            gymName: gymName,
            place: place,
            participantCount: participantCount,
            classPoints: classPoints,
            latitude: latitude,
            longitude: longitude
        )
    }
}
