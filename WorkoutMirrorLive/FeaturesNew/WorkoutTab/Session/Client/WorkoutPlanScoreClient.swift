//
//  WorkoutPlanScoreClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 03/03/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

struct WorkoutPlanScoreClient: Sendable {

    // MARK: - Operations

    /// Saves a workout plan score. If a record with the same `id` already exists, it is replaced (upsert).
    var save: @Sendable (WorkoutPlanScore) async throws -> Void

    /// Returns all executions of a given training plan, sorted by date descending.
    var fetchByTrainingSessionId: @Sendable (UUID) async throws -> [WorkoutPlanScore]

    /// Returns the execution record linked to a specific HKWorkout, or `nil` if none exists.
    var fetchByHKWorkoutId: @Sendable (UUID) async throws -> WorkoutPlanScore?

    /// Returns a single score by its ID, or `nil` if not found.
    var fetchById: @Sendable (UUID) async throws -> WorkoutPlanScore?

    /// Returns exercise names joined with " · " for each given HKWorkout linked to a plan.
    /// Workouts without a linked plan or without exercises are absent from the result.
    var fetchExerciseNames: @Sendable ([UUID]) async throws -> [UUID: String]
}

// MARK: - DependencyValues

extension DependencyValues {
    var workoutPlanScoreClient: WorkoutPlanScoreClient {
        get { self[WorkoutPlanScoreClientKey.self] }
        set { self[WorkoutPlanScoreClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum WorkoutPlanScoreClientKey: DependencyKey {

    static let liveValue: WorkoutPlanScoreClient = {
        @Dependency(\.defaultDatabase) var database

        return WorkoutPlanScoreClient(
            save: { score in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    // Upsert overwrites all columns — the `createdAt` of an existing
                    // record must survive (the auto-link → save results sequence
                    // would shift the creation date to the moment of editing).
                    let existingCreatedAt = try WorkoutPlanScoreRecord
                        .where { $0.id.eq(score.id) }
                        .fetchOne(db)?
                        .createdAt
                    let record = try WorkoutPlanScoreRecord(
                        from: score,
                        createdAt: existingCreatedAt ?? now,
                        updatedAt: now
                    )
                    let draft = WorkoutPlanScoreRecord.Draft(
                        id: record.id,
                        date: record.date,
                        trainingSessionId: record.trainingSessionId,
                        hkWorkoutId: record.hkWorkoutId,
                        resultsData: record.resultsData,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try WorkoutPlanScoreRecord.upsert { draft }.execute(db)
                }
            },
            fetchByTrainingSessionId: { id in
                try await database.read { db in
                    try WorkoutPlanScoreRecord
                        .where { $0.trainingSessionId.eq(id) }
                        .order { $0.date.desc() }
                        .fetchAll(db)
                        .map { try $0.toDomain() }
                }
            },
            fetchByHKWorkoutId: { id in
                try await database.read { db in
                    try WorkoutPlanScoreRecord
                        .where { $0.hkWorkoutId.eq(id) }
                        .fetchOne(db)
                        .map { try $0.toDomain() }
                }
            },
            fetchById: { id in
                try await database.read { db in
                    try WorkoutPlanScoreRecord
                        .where { $0.id.eq(id) }
                        .fetchOne(db)
                        .map { try $0.toDomain() }
                }
            },
            fetchExerciseNames: { workoutIds in
                try await database.read { db in
                    try WorkoutPlanScoreRecord
                        .where { $0.hkWorkoutId.in(workoutIds) }
                        .leftJoin(TrainingSessionRecord.all) { $0.trainingSessionId.eq($1.id) }
                        .select { ($0.hkWorkoutId, $0.resultsData, $1.workoutsData) }
                        .fetchAll(db)
                        .reduce(into: [UUID: String]()) { namesByWorkout, row in
                            let (hkWorkoutId, resultsData, workoutsData) = row
                            namesByWorkout[hkWorkoutId] = Self.exerciseNames(
                                resultsData: resultsData,
                                workoutsData: workoutsData
                            )
                        }
                }
            }
        )
    }()

    static var testValue: WorkoutPlanScoreClient {
        WorkoutPlanScoreClient(
            save: unimplemented("WorkoutPlanScoreClient.save"),
            fetchByTrainingSessionId: unimplemented("WorkoutPlanScoreClient.fetchByTrainingSessionId"),
            fetchByHKWorkoutId: unimplemented("WorkoutPlanScoreClient.fetchByHKWorkoutId"),
            fetchById: unimplemented("WorkoutPlanScoreClient.fetchById"),
            fetchExerciseNames: unimplemented("WorkoutPlanScoreClient.fetchExerciseNames", placeholder: [:])
        )
    }

    // Logged results win; the plan snapshot covers auto-linked workouts with empty results.
    nonisolated private static func exerciseNames(resultsData: Data, workoutsData: Data?) -> String? {
        let decoder = JSONDecoder()
        var names = withErrorReporting {
            try decoder.decode([WorkoutSessionResult].self, from: resultsData)
                .flatMap(\.exercises)
                .map(\.displayName)
        } ?? []
        if names.isEmpty, let workoutsData {
            names = withErrorReporting {
                try decoder.decode([WorkoutSessionNew].self, from: workoutsData)
                    .flatMap(\.exercises)
                    .map(\.displayName)
            } ?? []
        }
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }
}
