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
                        let draft = ExerciseLogRecord.Draft(
                            id: record.id,
                            date: record.date,
                            exerciseType: record.exerciseType,
                            unmatchedName: record.unmatchedName,
                            category: record.category,
                            workoutPlanScoreId: record.workoutPlanScoreId,
                            workoutSessionResultId: record.workoutSessionResultId,
                            wodName: record.wodName,
                            plannedReps: record.plannedReps,
                            plannedWeight: record.plannedWeight,
                            actualWeight: record.actualWeight,
                            actualReps: record.actualReps,
                            setsData: record.setsData,
                            scaling: record.scaling,
                            isPR: record.isPR,
                            avgHeartRate: record.avgHeartRate,
                            maxHeartRate: record.maxHeartRate,
                            phaseStartDate: record.phaseStartDate,
                            phaseEndDate: record.phaseEndDate,
                            timeInPhase: record.timeInPhase,
                            volumeLoad: record.volumeLoad,
                            tempoPerRound: record.tempoPerRound,
                            note: record.note,
                            editableUntil: record.editableUntil,
                            createdAt: record.createdAt,
                            updatedAt: record.updatedAt
                        )
                        try ExerciseLogRecord.upsert { draft }.execute(db)
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
