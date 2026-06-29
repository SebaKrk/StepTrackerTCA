//
//  WorkoutHRSnapshotClient.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 28/06/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

/// Per-workout HR snapshot persistence (IOS-00097-F).
///
/// **Freeze per-workout**: pierwszy raz gdy `MaxHeartRateClient.forWorkout` jest wywoływany
/// dla danego HKWorkout, snapshot się tworzy z **current** `@Shared(.appStorage("hrFormula"))`.
/// Następne wywołania zwracają cached value — zmiana formuły w Settings NIE wpływa
/// na historyczne workout'y.
public struct WorkoutHRSnapshotClient: Sendable {

    // MARK: - Operations

    /// Zwraca snapshot dla danego HKWorkout, lub `nil` jeśli jeszcze nie utworzony.
    public var fetchByHKWorkoutId: @Sendable (UUID) async throws -> WorkoutHRSnapshot?

    /// Zapisuje snapshot (upsert — primary key `id`, unique constraint na `hkWorkoutId`).
    public var save: @Sendable (WorkoutHRSnapshot) async throws -> Void
}

// MARK: - DependencyValues

public extension DependencyValues {
    var workoutHRSnapshotClient: WorkoutHRSnapshotClient {
        get { self[WorkoutHRSnapshotClientKey.self] }
        set { self[WorkoutHRSnapshotClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

public enum WorkoutHRSnapshotClientKey: DependencyKey {

    public static let liveValue: WorkoutHRSnapshotClient = {
        @Dependency(\.defaultDatabase) var database

        return WorkoutHRSnapshotClient(
            fetchByHKWorkoutId: { hkWorkoutId in
                try await database.read { db in
                    try WorkoutHRSnapshotRecord
                        .where { $0.hkWorkoutId.eq(hkWorkoutId) }
                        .fetchOne(db)
                        .map { $0.toDomain() }
                }
            },
            save: { snapshot in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let record = WorkoutHRSnapshotRecord(from: snapshot, createdAt: now, updatedAt: now)
                    let draft = WorkoutHRSnapshotRecord.Draft(
                        id: record.id,
                        hkWorkoutId: record.hkWorkoutId,
                        maxHR: record.maxHR,
                        formulaRawValue: record.formulaRawValue,
                        ageAtWorkout: record.ageAtWorkout,
                        biologicalSexRawValue: record.biologicalSexRawValue,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try WorkoutHRSnapshotRecord.upsert { draft }.execute(db)
                }
            }
        )
    }()

    public static var testValue: WorkoutHRSnapshotClient {
        WorkoutHRSnapshotClient(
            fetchByHKWorkoutId: unimplemented("WorkoutHRSnapshotClient.fetchByHKWorkoutId"),
            save: unimplemented("WorkoutHRSnapshotClient.save")
        )
    }
}
