//
//  ExerciseLogClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 24/04/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

struct ExerciseLogClient: Sendable {
    var save: @Sendable ([ExerciseLog]) async throws -> Void
    var fetchByExerciseType: @Sendable (ExerciseType) async throws -> [ExerciseLog]
    var fetchByWorkoutPlanScoreId: @Sendable (UUID) async throws -> [ExerciseLog]
    var fetchByDateRange: @Sendable (Date, Date) async throws -> [ExerciseLog]
}

// MARK: - DependencyValues

extension DependencyValues {
    var exerciseLogClient: ExerciseLogClient {
        get { self[ExerciseLogClientKey.self] }
        set { self[ExerciseLogClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum ExerciseLogClientKey: DependencyKey {

    static let liveValue: ExerciseLogClient = {
        @Dependency(\.defaultDatabase) var database

        return ExerciseLogClient(
            save: { logs in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    for log in logs {
                        let record = ExerciseLogRecord(from: log, createdAt: now, updatedAt: now)
                        try ExerciseLogRecord.upsert { ExerciseLogRecord.Draft(record) }.execute(db)
                    }
                }
            },
            fetchByExerciseType: { type in
                try await database.read { db in
                    try ExerciseLogRecord
                        .where { $0.exerciseType.eq(type.rawValue) }
                        .order { $0.date.desc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            },
            fetchByWorkoutPlanScoreId: { id in
                try await database.read { db in
                    try ExerciseLogRecord
                        .where { $0.workoutPlanScoreId.eq(id) }
                        .order { $0.date.desc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            },
            fetchByDateRange: { start, end in
                try await database.read { db in
                    try ExerciseLogRecord
                        .where { $0.date.gte(start) && $0.date.lt(end) }
                        .order { $0.date.desc() }
                        .fetchAll(db)
                        .map { $0.toDomain() }
                }
            }
        )
    }()

    static var testValue: ExerciseLogClient {
        ExerciseLogClient(
            save: unimplemented("ExerciseLogClient.save"),
            fetchByExerciseType: unimplemented("ExerciseLogClient.fetchByExerciseType"),
            fetchByWorkoutPlanScoreId: unimplemented("ExerciseLogClient.fetchByWorkoutPlanScoreId"),
            fetchByDateRange: unimplemented("ExerciseLogClient.fetchByDateRange")
        )
    }
}
