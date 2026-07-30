//
//  EffortScoreClient.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 07/07/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

/// Per-workout effort points persistence (IOS-00099).
///
/// Points are computed LIVE on-device during the workout (the same accumulator
/// shown on screen and sent to GymRoom) and frozen at teardown. This client only
/// stores and reads that final value — it never computes from HealthKit and never
/// recomputes historical workouts. "A result is a result."
public struct EffortScoreClient: Sendable {

    // MARK: - Operations

    /// Persists a frozen score (upsert by `id`, unique on `hkWorkoutId`). Called
    /// once, from the post-save hook, with the value captured at workout end.
    public var save: @Sendable (WorkoutEffortScore) async throws -> Void

    /// Returns the stored score for the given HKWorkout, or `nil` if none — i.e.
    /// workouts recorded before this feature shipped (no backfill, no lazy compute;
    /// the UI hides the section for `nil`).
    public var fetchByHKWorkoutId: @Sendable (UUID) async throws -> WorkoutEffortScore?

    /// Removes the stored score — call when the workout is deleted from HealthKit
    /// so its points don't linger in monthly aggregates.
    public var deleteByHKWorkoutId: @Sendable (UUID) async throws -> Void
}

// MARK: - DependencyValues

public extension DependencyValues {
    var effortScoreClient: EffortScoreClient {
        get { self[EffortScoreClientKey.self] }
        set { self[EffortScoreClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

public enum EffortScoreClientKey: DependencyKey {

    public static let liveValue: EffortScoreClient = {
        @Dependency(\.defaultDatabase) var database

        return EffortScoreClient(
            save: { score in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    // Reuse the existing row's id for this hkWorkoutId so a duplicate
                    // save (e.g. `.workoutSaved` delivered twice via sendMessage +
                    // transferUserInfo fallback) UPDATES in place via the id-conflict
                    // path instead of minting a fresh id and hitting the
                    // UNIQUE(hkWorkoutId) index → throw. Read + write are in one
                    // `database.write`, so it's atomic under SQLite's write
                    // serialization — no check-then-act race.
                    let existingId = try WorkoutEffortScoreRecord
                        .where { $0.hkWorkoutId.eq(score.hkWorkoutId) }
                        .fetchOne(db)?
                        .id
                    let record = WorkoutEffortScoreRecord(from: score, createdAt: now, updatedAt: now)
                    let draft = WorkoutEffortScoreRecord.Draft(
                        id: existingId ?? record.id,
                        hkWorkoutId: record.hkWorkoutId,
                        points: record.points,
                        workoutStartDate: record.workoutStartDate,
                        secondsZone1: record.secondsZone1,
                        secondsZone2: record.secondsZone2,
                        secondsZone3: record.secondsZone3,
                        secondsZone4: record.secondsZone4,
                        secondsZone5: record.secondsZone5,
                        weightsVersion: record.weightsVersion,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try WorkoutEffortScoreRecord.upsert { draft }.execute(db)
                }
            },
            fetchByHKWorkoutId: { hkWorkoutId in
                try await database.read { db in
                    try WorkoutEffortScoreRecord
                        .where { $0.hkWorkoutId.eq(hkWorkoutId) }
                        .fetchOne(db)
                        .map { $0.toDomain() }
                }
            },
            deleteByHKWorkoutId: { hkWorkoutId in
                try await database.write { db in
                    try WorkoutEffortScoreRecord
                        .where { $0.hkWorkoutId.eq(hkWorkoutId) }
                        .delete()
                        .execute(db)
                }
            }
        )
    }()

    public static var testValue: EffortScoreClient {
        EffortScoreClient(
            save: unimplemented("EffortScoreClient.save"),
            fetchByHKWorkoutId: unimplemented("EffortScoreClient.fetchByHKWorkoutId"),
            deleteByHKWorkoutId: unimplemented("EffortScoreClient.deleteByHKWorkoutId")
        )
    }
}
