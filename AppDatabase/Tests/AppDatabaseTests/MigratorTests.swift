//
//  MigratorTests.swift
//  AppDatabase
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import Foundation
import SQLiteData
import Testing
@testable import AppDatabase

@Suite("AppDatabase migrator")
struct MigratorTests {

    @Test("All migrations v1…v12 apply cleanly on an empty in-memory database")
    func migratorAppliesCleanly() throws {
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)

        let prEntriesTableExists = try database.read { db in
            try Bool.fetchOne(
                db,
                sql: "SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'prEntryRecords')"
            ) ?? false
        }
        #expect(prEntriesTableExists)
    }
}
