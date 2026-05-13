//
//  Schema.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import Dependencies
import Foundation
import SQLiteData

extension DependencyValues {

    /// Bootstraps the SQLite database and registers `defaultDatabase` dependency.
    ///
    /// Call once in app entry point:
    /// ```swift
    /// prepareDependencies {
    ///     do {
    ///         try $0.bootstrapDatabase()
    ///     } catch {
    ///         fatalError("Database failed to initialize: \(error)")
    ///     }
    /// }
    /// ```
    ///
    /// TODO: IOS-00071-iCloud — swap `defaultDatabase()` na sync engine.
    public mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_userProfile") { db in
            try #sql("""
                CREATE TABLE "userProfileRecords" (
                  "id" TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "name" TEXT NOT NULL DEFAULT '',
                  "surname" TEXT NOT NULL DEFAULT '',
                  "nickname" TEXT NOT NULL DEFAULT '',
                  "createdAt" TEXT NOT NULL,
                  "updatedAt" TEXT NOT NULL,
                  "ckRecordData" BLOB
                ) STRICT
                """)
            .execute(db)
        }

        migrator.registerMigration("v2_addEmail") { db in
            try #sql("""
                ALTER TABLE "userProfileRecords"
                ADD COLUMN "email" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
                """)
            .execute(db)
        }

        migrator.registerMigration("v3_trainingSession") { db in
            try #sql("""
                CREATE TABLE "trainingSessionRecords" (
                  "id"           TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "date"         TEXT NOT NULL,
                  "title"        TEXT NOT NULL DEFAULT '',
                  "activity"     TEXT NOT NULL DEFAULT '',
                  "location"     TEXT NOT NULL DEFAULT '',
                  "warmUpData"   BLOB,
                  "workoutsData" BLOB NOT NULL,
                  "coolDownData" BLOB,
                  "createdAt"    TEXT NOT NULL,
                  "updatedAt"    TEXT NOT NULL,
                  "ckRecordData" BLOB
                ) STRICT
                """)
            .execute(db)
        }

        migrator.registerMigration("v4_workoutPlanScore") { db in
            try #sql("""
                CREATE TABLE "workoutPlanScoreRecords" (
                  "id"                TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "date"              TEXT NOT NULL,
                  "trainingSessionId" TEXT NOT NULL,
                  "hkWorkoutId"       TEXT NOT NULL,
                  "resultsData"       BLOB NOT NULL,
                  "createdAt"         TEXT NOT NULL,
                  "updatedAt"         TEXT NOT NULL,
                  "ckRecordData"      BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_workoutPlanScoreRecords_on_trainingSessionId"
                ON "workoutPlanScoreRecords"("trainingSessionId")
                """)
            .execute(db)
        }

        migrator.registerMigration("v5_exerciseLog") { db in
            try #sql("""
                CREATE TABLE "exerciseLogRecords" (
                  "id"                  TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "date"                TEXT NOT NULL,
                  "exerciseType"        TEXT,
                  "unmatchedName"       TEXT,
                  "category"            TEXT,
                  "workoutPlanScoreId"  TEXT,
                  "wodName"             TEXT,
                  "plannedReps"         TEXT,
                  "plannedWeight"       REAL,
                  "actualWeight"        REAL,
                  "actualReps"          TEXT,
                  "scaling"             TEXT NOT NULL DEFAULT 'rx',
                  "isPR"                INTEGER NOT NULL DEFAULT 0,
                  "avgHeartRate"        REAL,
                  "maxHeartRate"        REAL,
                  "phaseStartDate"      TEXT,
                  "phaseEndDate"        TEXT,
                  "timeInPhase"         REAL,
                  "volumeLoad"          REAL,
                  "tempoPerRound"       REAL,
                  "note"                TEXT,
                  "editableUntil"       TEXT,
                  "createdAt"           TEXT NOT NULL,
                  "updatedAt"           TEXT NOT NULL,
                  "ckRecordData"        BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_exerciseLogRecords_on_exerciseType"
                ON "exerciseLogRecords"("exerciseType")
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_exerciseLogRecords_on_workoutPlanScoreId"
                ON "exerciseLogRecords"("workoutPlanScoreId")
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_exerciseLogRecords_on_date"
                ON "exerciseLogRecords"("date")
                """)
            .execute(db)
        }

        try migrator.migrate(database)
        defaultDatabase = database

        #if DEBUG
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        print("📦 [AppDatabase] path: \(appSupport?.path ?? "unknown")")
        #endif
    }
}
