//
//  ClassParticipationClient.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 15/07/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

/// Persistence for a participant's GymRoom class attendance (IOS-00104-C).
///
/// The value is frozen at class end from the iPad recap (place, count, coordinates)
/// combined with what the participant knew locally (gymName, class points). This
/// client only stores and reads it — never recomputed. Separate from
/// `EffortScoreClient` because attendance shows even for a zero-point class.
public struct ClassParticipationClient: Sendable {

    // MARK: - Operations

    /// Persists a frozen participation (upsert by `id`, unique on `hkWorkoutId`).
    /// Called once from the post-save hook when the pending recap is consumed.
    public var save: @Sendable (ClassParticipation) async throws -> Void

    /// Returns the stored participation for the given HKWorkout, or `nil` if the
    /// workout wasn't part of a class (the UI hides the recap section for `nil`).
    public var fetchByHKWorkoutId: @Sendable (UUID) async throws -> ClassParticipation?

    /// Removes the stored participation — call when the workout is deleted so a
    /// dangling recap doesn't linger.
    public var deleteByHKWorkoutId: @Sendable (UUID) async throws -> Void
}

// MARK: - DependencyValues

public extension DependencyValues {
    var classParticipationClient: ClassParticipationClient {
        get { self[ClassParticipationClientKey.self] }
        set { self[ClassParticipationClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

public enum ClassParticipationClientKey: DependencyKey {

    public static let liveValue: ClassParticipationClient = {
        @Dependency(\.defaultDatabase) var database

        return ClassParticipationClient(
            save: { participation in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    // Reuse the existing row's id for this hkWorkoutId so a duplicate
                    // save UPDATES in place instead of hitting the UNIQUE(hkWorkoutId)
                    // index. Read + write in one `database.write` → atomic, no race.
                    let existingId = try ClassParticipationRecord
                        .where { $0.hkWorkoutId.eq(participation.hkWorkoutId) }
                        .fetchOne(db)?
                        .id
                    let record = ClassParticipationRecord(from: participation, createdAt: now, updatedAt: now)
                    let draft = ClassParticipationRecord.Draft(
                        id: existingId ?? record.id,
                        hkWorkoutId: record.hkWorkoutId,
                        classSessionId: record.classSessionId,
                        gymName: record.gymName,
                        place: record.place,
                        participantCount: record.participantCount,
                        classPoints: record.classPoints,
                        latitude: record.latitude,
                        longitude: record.longitude,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try ClassParticipationRecord.upsert { draft }.execute(db)
                }
            },
            fetchByHKWorkoutId: { hkWorkoutId in
                try await database.read { db in
                    try ClassParticipationRecord
                        .where { $0.hkWorkoutId.eq(hkWorkoutId) }
                        .fetchOne(db)
                        .map { $0.toDomain() }
                }
            },
            deleteByHKWorkoutId: { hkWorkoutId in
                try await database.write { db in
                    try ClassParticipationRecord
                        .where { $0.hkWorkoutId.eq(hkWorkoutId) }
                        .delete()
                        .execute(db)
                }
            }
        )
    }()

    public static var testValue: ClassParticipationClient {
        ClassParticipationClient(
            save: unimplemented("ClassParticipationClient.save"),
            fetchByHKWorkoutId: unimplemented("ClassParticipationClient.fetchByHKWorkoutId"),
            deleteByHKWorkoutId: unimplemented("ClassParticipationClient.deleteByHKWorkoutId")
        )
    }
}
