//
//  TrainingSessionClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 22/03/2026.
//

import AppDatabase
import Dependencies
import Foundation
import SharedModels
import SQLiteData

struct TrainingSessionClient: Sendable {
    var save:     @Sendable (TrainingSession) async throws -> Void
    var fetchAll: @Sendable () async throws -> [TrainingSession]
    var delete:   @Sendable (UUID) async throws -> Void
}

extension DependencyValues {
    var trainingSessionClient: TrainingSessionClient {
        get { self[TrainingSessionClientKey.self] }
        set { self[TrainingSessionClientKey.self] = newValue }
    }
}

private enum TrainingSessionClientKey: DependencyKey {

    static let liveValue: TrainingSessionClient = {
        @Dependency(\.defaultDatabase) var database

        return TrainingSessionClient(
            save: { session in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let record = try TrainingSessionRecord(from: session, createdAt: now, updatedAt: now)
                    let draft = TrainingSessionRecord.Draft(
                        id: record.id,
                        date: record.date,
                        title: record.title,
                        activity: record.activity,
                        location: record.location,
                        warmUpData: record.warmUpData,
                        workoutsData: record.workoutsData,
                        coolDownData: record.coolDownData,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try TrainingSessionRecord.upsert { draft }.execute(db)
                }
            },
            fetchAll: {
                try await database.read { db in
                    try TrainingSessionRecord
                        .order { $0.date.desc() }
                        .fetchAll(db)
                        .map { try $0.toDomain() }
                }
            },
            delete: { id in
                try await database.write { db in
                    try TrainingSessionRecord
                        .find(id)
                        .delete()
                        .execute(db)
                }
            }
        )
    }()

    static var testValue: TrainingSessionClient {
        TrainingSessionClient(
            save: unimplemented("TrainingSessionClient.save"),
            fetchAll: unimplemented("TrainingSessionClient.fetchAll"),
            delete: unimplemented("TrainingSessionClient.delete")
        )
    }
}
