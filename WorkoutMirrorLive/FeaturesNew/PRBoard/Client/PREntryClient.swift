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

/// Write boundary for PR Board entries. PR Board reads go through `@FetchAll`
/// in feature State; `fetchAll` serves one-shot reads outside the board.
struct PREntryClient: Sendable {

    /// Upserts one entry (same id overwrites — used by future edit flows).
    var save: @Sendable (PREntry) async throws -> Void

    /// Deletes one entry by id — PRs recompute from the remaining history (FR-007).
    var delete: @Sendable (UUID) async throws -> Void

    /// One-shot snapshot of all entries — for consumers whose State must stay
    /// Equatable (e.g. Summary PR suggestions), where `@FetchAll` doesn't fit.
    var fetchAll: @Sendable () async throws -> [PREntry]
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
                    // Draft(record) is compiler-maintained — a hand-written field
                    // list silently dropped scalingNote once (IOS-00128 review).
                    let record = PREntryRecord(from: entry, updatedAt: now)
                    try PREntryRecord.upsert { PREntryRecord.Draft(record) }.execute(db)
                }
            },
            delete: { id in
                try await database.write { db in
                    try PREntryRecord
                        .where { $0.id.eq(id) }
                        .delete()
                        .execute(db)
                }
            },
            fetchAll: {
                try await database.read { db in
                    try PREntryRecord.all.fetchAll(db)
                }
                .compactMap { $0.toDomain() }
            }
        )
    }()

    static var testValue: PREntryClient {
        PREntryClient(
            save: unimplemented("PREntryClient.save"),
            delete: unimplemented("PREntryClient.delete"),
            fetchAll: unimplemented("PREntryClient.fetchAll", placeholder: [])
        )
    }
}
