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

    @Test("All migrations v1…v13 apply cleanly on an empty in-memory database")
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

    // Regression guard for the 2026-08-03 incident: an empty-database test cannot
    // catch data destruction, because the erase path only triggers on a database
    // that already has applied migrations. This test builds a v11 database WITH
    // rows, migrates to the latest schema, and asserts the values are untouched.
    @Test("Rows inserted at v11 survive migration to the latest schema unchanged")
    func dataSurvivesMigrationFromV11() throws {
        let database = try DatabaseQueue()
        let migrator = AppDatabaseSchema.makeMigrator()
        try migrator.migrate(database, upTo: "v11_classParticipation")

        // Raw SQL fixtures on purpose: @Table structs map the NEWEST schema,
        // so they must not be used to author rows for an older one.
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "userProfileRecords"
                  ("id", "name", "surname", "nickname", "createdAt", "updatedAt", "email")
                VALUES
                  ('user-1', 'Alice', 'Smith', 'ala', '2026-07-01T08:00:00.000Z', '2026-07-01T08:00:00.000Z', 'alice@example.com')
                """)
            try db.execute(sql: """
                INSERT INTO "trainingSessionRecords"
                  ("id", "date", "title", "activity", "location", "workoutsData", "createdAt", "updatedAt")
                VALUES
                  ('session-1', '2026-07-02T17:30:00.000Z', 'Leg day', 'strength', 'Box', X'01AB', '2026-07-02T17:30:00.000Z', '2026-07-02T17:30:00.000Z')
                """)
            try db.execute(sql: """
                INSERT INTO "exerciseLogRecords"
                  ("id", "date", "exerciseType", "actualWeight", "scaling", "isPR", "createdAt", "updatedAt")
                VALUES
                  ('log-1', '2026-07-02T17:45:00.000Z', 'backSquat', 142.5, 'rx', 1, '2026-07-02T17:45:00.000Z', '2026-07-02T17:45:00.000Z')
                """)
            try db.execute(sql: """
                INSERT INTO "workoutPlanScoreRecords"
                  ("id", "date", "trainingSessionId", "hkWorkoutId", "resultsData", "createdAt", "updatedAt")
                VALUES
                  ('score-1', '2026-07-02T18:00:00.000Z', 'session-1', 'hk-1', X'02CD', '2026-07-02T18:00:00.000Z', '2026-07-02T18:00:00.000Z')
                """)
        }

        try migrator.migrate(database)

        try database.read { db in
            #expect(
                try String.fetchOne(db, sql: "SELECT \"name\" FROM \"userProfileRecords\" WHERE \"id\" = 'user-1'") == "Alice"
            )
            #expect(
                try String.fetchOne(db, sql: "SELECT \"email\" FROM \"userProfileRecords\" WHERE \"id\" = 'user-1'") == "alice@example.com"
            )
            #expect(
                try String.fetchOne(db, sql: "SELECT \"title\" FROM \"trainingSessionRecords\" WHERE \"id\" = 'session-1'") == "Leg day"
            )
            #expect(
                try Data.fetchOne(db, sql: "SELECT \"workoutsData\" FROM \"trainingSessionRecords\" WHERE \"id\" = 'session-1'") == Data([0x01, 0xAB])
            )
            #expect(
                try Double.fetchOne(db, sql: "SELECT \"actualWeight\" FROM \"exerciseLogRecords\" WHERE \"id\" = 'log-1'") == 142.5
            )
            #expect(
                try String.fetchOne(db, sql: "SELECT \"exerciseType\" FROM \"exerciseLogRecords\" WHERE \"id\" = 'log-1'") == "backSquat"
            )
            #expect(
                try String.fetchOne(db, sql: "SELECT \"hkWorkoutId\" FROM \"workoutPlanScoreRecords\" WHERE \"id\" = 'score-1'") == "hk-1"
            )
            let rowCounts = try [
                Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"userProfileRecords\""),
                Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"trainingSessionRecords\""),
                Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"exerciseLogRecords\""),
                Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"workoutPlanScoreRecords\""),
            ]
            #expect(rowCounts == [1, 1, 1, 1])
        }
    }

    // v13 rebuilds prEntryRecords to relax the context NOT NULL. Fixture rows
    // are authored at v12 (raw SQL) and must survive the rebuild; historical
    // 'fresh' was the form default, never a user choice — v13 maps it to NULL.
    @Test("v13 rebuild keeps PR entries; default 'fresh' context becomes NULL")
    func prEntryContextMigratesToOptional() throws {
        let database = try DatabaseQueue()
        let migrator = AppDatabaseSchema.makeMigrator()
        try migrator.migrate(database, upTo: "v12_prEntries")

        try database.write { db in
            try db.execute(sql: """
                INSERT INTO "prEntryRecords"
                  ("id", "movementId", "date", "scoreType", "weightKg", "timeSeconds", "equipment", "context", "createdAt", "updatedAt")
                VALUES
                  ('entry-1', 'back-squat', '2026-09-01 10:00:00', 'weight', 150.0, NULL, 'belt', 'fresh', '2026-09-01 10:00:00', '2026-09-01 10:00:00'),
                  ('entry-2', 'fran', '2026-09-02 10:00:00', 'time', NULL, 390, '', 'competition', '2026-09-02 10:00:00', '2026-09-02 10:00:00')
                """)
        }

        try migrator.migrate(database)

        try database.read { db in
            // Bare `try` bindings on purpose — `try` inside a macro argument does
            // not count toward the closure's throws inference.
            let rowCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"prEntryRecords\"")
            let freshContext = try String.fetchOne(db, sql: "SELECT \"context\" FROM \"prEntryRecords\" WHERE \"id\" = 'entry-1'")
            let chosenContext = try String.fetchOne(db, sql: "SELECT \"context\" FROM \"prEntryRecords\" WHERE \"id\" = 'entry-2'")
            let weightKg = try Double.fetchOne(db, sql: "SELECT \"weightKg\" FROM \"prEntryRecords\" WHERE \"id\" = 'entry-1'")
            let timeSeconds = try Int.fetchOne(db, sql: "SELECT \"timeSeconds\" FROM \"prEntryRecords\" WHERE \"id\" = 'entry-2'")
            #expect(rowCount == 2)
            #expect(freshContext == nil)
            #expect(chosenContext == "competition")
            #expect(weightKg == 150.0)
            #expect(timeSeconds == 390)
        }
    }

    // hasSchemaChanges is the exact predicate that decides the DEBUG-only
    // eraseDatabaseOnSchemaChange wipe in bootstrapDatabase(). It must be false
    // for a database migrated by the current migrator — any edit or rename of an
    // already-registered migration flips it to true and fails this test.
    @Test("hasSchemaChanges is false after a full migration (DEBUG erase predicate)")
    func noSchemaChangesAfterFullMigration() throws {
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)

        let hasChanges = try database.read { db in
            try AppDatabaseSchema.makeMigrator().hasSchemaChanges(db)
        }
        #expect(hasChanges == false)
    }

    @Test("Every table registered by the migrator exists after a full migration")
    func allTablesExistAfterFullMigration() throws {
        let database = try DatabaseQueue()
        try AppDatabaseSchema.makeMigrator().migrate(database)

        let expectedTables = [
            "athleteSessionRecords",
            "classParticipationRecords",
            "classSessionRecords",
            "exerciseLogRecords",
            "gymClassRecords",
            "prEntryRecords",
            "trainingSessionRecords",
            "userProfileRecords",
            "workoutEffortScoreRecords",
            "workoutHRSnapshotRecords",
            "workoutPlanScoreRecords",
        ]
        let actualTables = try database.read { db in
            try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'grdb_migrations' ORDER BY name"
            )
        }
        #expect(actualTables == expectedTables)
    }
}
