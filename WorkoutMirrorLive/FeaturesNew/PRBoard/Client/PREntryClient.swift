//
//  PREntryClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import AppDatabase
import ComposableArchitecture
import Foundation
import SharedModels
import SQLiteData

// MARK: - Client

/// Write boundary for PR Board entries. Reads go through `@FetchAll` in
/// feature State (phase 4) — the client only persists; S-05 adds delete.
struct PREntryClient: Sendable {

    /// Upserts one entry (same id overwrites — used by future edit flows).
    var save: @Sendable (PREntry) async throws -> Void
}

// MARK: - DependencyValues

extension DependencyValues {
    var prEntryClient: PREntryClient {
        get { self[PREntryClientKey.self] }
        set { self[PREntryClientKey.self] = newValue }
    }
}

// MARK: - DependencyKey

private enum PREntryClientKey: DependencyKey {

    static let liveValue: PREntryClient = {
        @Dependency(\.defaultDatabase) var database

        return PREntryClient(
            save: { entry in
                @Dependency(\.date.now) var now
                try await database.write { db in
                    let record = PREntryRecord(from: entry, updatedAt: now)
                    let draft = PREntryRecord.Draft(
                        id: record.id,
                        movementId: record.movementId,
                        date: record.date,
                        scoreType: record.scoreType,
                        weightKg: record.weightKg,
                        timeSeconds: record.timeSeconds,
                        rounds: record.rounds,
                        extraReps: record.extraReps,
                        isRx: record.isRx,
                        equipment: record.equipment,
                        rpe: record.rpe,
                        note: record.note,
                        bodyWeightKg: record.bodyWeightKg,
                        context: record.context,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    try PREntryRecord.upsert { draft }.execute(db)
                }
            }
        )
    }()

    static var testValue: PREntryClient {
        PREntryClient(
            save: unimplemented("PREntryClient.save")
        )
    }
}
