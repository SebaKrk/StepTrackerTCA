//
//  ExerciseCatalogClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 12/07/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import OSLog
import SharedModels
import SQLiteData

// MARK: - Client

/// One-time repair of historical `.unknown` exercise data after a catalog
/// extension. Matching runs once at scan time and its result is frozen in the
/// database, so new cases/aliases only fix future scans — this client replays
/// the matcher over old data (exercise logs + plan blobs).
struct ExerciseCatalogClient: Sendable {

    /// Re-matches `.unknown` exercise logs and training-plan exercises against
    /// the current catalog. No-op when the stored catalog version is current;
    /// idempotent, so an interrupted run simply repeats on next launch.
    var rematchIfNeeded: @Sendable () async throws -> Void
}

// MARK: - DependencyValues

extension DependencyValues {
    var exerciseCatalogClient: ExerciseCatalogClient {
        get { self[ExerciseCatalogClientKey.self] }
        set { self[ExerciseCatalogClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum ExerciseCatalogClientKey: DependencyKey {

    static let liveValue: ExerciseCatalogClient = {
        @Dependency(\.defaultDatabase) var database

        return ExerciseCatalogClient(
            rematchIfNeeded: {
                @Shared(.appStorage("exerciseCatalogRematchVersion")) var rematchedVersion = 0
                guard rematchedVersion < ExerciseType.catalogVersion else { return }
                @Dependency(\.date.now) var now

                // Exercise logs: rows still marked unknown keep the raw OCR/AI
                // name in `unmatchedName` — replay it through the matcher.
                // `unmatchedName` itself stays untouched (provenance, shown in
                // the exercise-detail history).
                var logsUpdated = 0
                try await database.write { db in
                    let unknownLogs = try ExerciseLogRecord
                        .where { $0.exerciseType.is(nil) || $0.exerciseType.eq(ExerciseType.unknown.rawValue) }
                        .fetchAll(db)
                    for log in unknownLogs {
                        guard let rawName = log.unmatchedName else { continue }
                        let resolved = ExerciseType.matched(fromRawName: rawName)
                        guard resolved != .unknown else { continue }
                        try ExerciseLogRecord
                            .where { $0.id.eq(log.id) }
                            .update {
                                // Plain Swift values must be explicitly bound
                                // into query expressions (library requirement).
                                $0.exerciseType = #bind(resolved.rawValue)
                                $0.category = #bind(resolved.category.rawValue)
                                $0.updatedAt = #bind(now)
                            }
                            .execute(db)
                        logsUpdated += 1
                    }
                }

                // Training plans: exercises live JSON-encoded in `workoutsData`,
                // so logs created from an old plan would stay unknown forever
                // without this pass. Only records that actually changed are
                // re-encoded and written back.
                var plansUpdated = 0
                try await database.write { db in
                    let planRecords = try TrainingSessionRecord.fetchAll(db)
                    let encoder = JSONEncoder()
                    for record in planRecords {
                        guard let session = try? record.toDomain(),
                              let rematched = session.rematchedAgainstCatalog()
                        else { continue }
                        let workoutsData = try encoder.encode(rematched.workouts)
                        try TrainingSessionRecord
                            .where { $0.id.eq(record.id) }
                            .update {
                                $0.workoutsData = #bind(workoutsData)
                                $0.updatedAt = #bind(now)
                            }
                            .execute(db)
                        plansUpdated += 1
                    }
                }

                $rematchedVersion.withLock { $0 = ExerciseType.catalogVersion }
                Logger.session.info("[Catalog] rematch v\(ExerciseType.catalogVersion): \(logsUpdated) logs, \(plansUpdated) plans updated")
            }
        )
    }()

    static var testValue: ExerciseCatalogClient {
        ExerciseCatalogClient(
            rematchIfNeeded: unimplemented("ExerciseCatalogClient.rematchIfNeeded")
        )
    }

    static var previewValue: ExerciseCatalogClient {
        ExerciseCatalogClient(rematchIfNeeded: {})
    }
}
