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

        var migrator = AppDatabaseSchema.makeMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        try migrator.migrate(database)
        defaultDatabase = database

        #if DEBUG
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        print("📦 [AppDatabase] path: \(appSupport?.path ?? "unknown")")
        #endif
    }
}

/// Full append-only migrator (v1…) — single source of truth shared by
/// `bootstrapDatabase()` and the migrator test.
public enum AppDatabaseSchema {

    public static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

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

        // Per-set tracking columns added in IOS-00084.
        // NOTE: never edit an already-registered migration body — DatabaseMigrator
        // tracks migrations by name, so a v5 modification would never re-run for
        // users who already migrated. Always append a new vN migration.
        migrator.registerMigration("v6_exerciseLog_addSetsAndResultId") { db in
            try #sql("""
                ALTER TABLE "exerciseLogRecords" ADD COLUMN "workoutSessionResultId" TEXT
                """)
            .execute(db)
            try #sql("""
                ALTER TABLE "exerciseLogRecords" ADD COLUMN "setsData" BLOB
                """)
            .execute(db)
        }

        // GymRoom (IPAD-00090) — schedule template + session records + athlete records.
        // Three tables: templates re-usable, sessions per Start, athletes per peer-in-session.
        migrator.registerMigration("v7_gymRoom") { db in
            try #sql("""
                CREATE TABLE "gymClassRecords" (
                  "id"              TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "name"            TEXT NOT NULL DEFAULT '',
                  "location"        TEXT NOT NULL DEFAULT '',
                  "scheduledAt"     TEXT,
                  "maxParticipants" INTEGER NOT NULL DEFAULT 8,
                  "createdAt"       TEXT NOT NULL,
                  "updatedAt"       TEXT NOT NULL,
                  "ckRecordData"    BLOB
                ) STRICT
                """)
            .execute(db)

            try #sql("""
                CREATE TABLE "classSessionRecords" (
                  "id"           TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "gymClassId"   TEXT NOT NULL,
                  "className"    TEXT NOT NULL DEFAULT '',
                  "location"     TEXT NOT NULL DEFAULT '',
                  "startedAt"    TEXT NOT NULL,
                  "endedAt"      TEXT,
                  "createdAt"    TEXT NOT NULL,
                  "updatedAt"    TEXT NOT NULL,
                  "ckRecordData" BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_classSessionRecords_on_gymClassId"
                ON "classSessionRecords"("gymClassId")
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_classSessionRecords_on_startedAt"
                ON "classSessionRecords"("startedAt")
                """)
            .execute(db)

            try #sql("""
                CREATE TABLE "athleteSessionRecords" (
                  "id"                  TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "classSessionId"      TEXT NOT NULL,
                  "deviceID"            TEXT NOT NULL,
                  "nick"                TEXT NOT NULL DEFAULT '',
                  "maxHR"               INTEGER NOT NULL DEFAULT 190,
                  "hrSamplesData"       BLOB NOT NULL,
                  "aggregatedStatsData" BLOB NOT NULL,
                  "joinedAt"            TEXT NOT NULL,
                  "leftAt"              TEXT,
                  "createdAt"           TEXT NOT NULL,
                  "updatedAt"           TEXT NOT NULL,
                  "ckRecordData"        BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_athleteSessionRecords_on_classSessionId"
                ON "athleteSessionRecords"("classSessionId")
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_athleteSessionRecords_on_deviceID"
                ON "athleteSessionRecords"("deviceID")
                """)
            .execute(db)
        }

        // Per-workout HR formula freeze snapshot (IOS-00097-F).
        // Snapshot table stores maxHR + formula z momentu pierwszej kalkulacji per HKWorkout.
        // Freeze zachowuje stare wartości gdy user zmieni formułę w Settings.
        migrator.registerMigration("v8_workoutHRSnapshot") { db in
            try #sql("""
                CREATE TABLE "workoutHRSnapshotRecords" (
                  "id"                     TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "hkWorkoutId"            TEXT NOT NULL,
                  "maxHR"                  REAL NOT NULL,
                  "formulaRawValue"        TEXT NOT NULL,
                  "ageAtWorkout"           INTEGER NOT NULL,
                  "biologicalSexRawValue"  TEXT NOT NULL,
                  "createdAt"              TEXT NOT NULL,
                  "updatedAt"              TEXT NOT NULL,
                  "ckRecordData"           BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE UNIQUE INDEX "index_workoutHRSnapshotRecords_on_hkWorkoutId"
                ON "workoutHRSnapshotRecords"("hkWorkoutId")
                """)
            .execute(db)
        }

        // Effort points per personal workout (IOS-00099). Frozen points + per-zone
        // seconds breakdown + weights version. workoutStartDate is denormalized
        // and indexed for period aggregates (monthly sum) without HealthKit.
        migrator.registerMigration("v9_workoutEffortScore") { db in
            try #sql("""
                CREATE TABLE "workoutEffortScoreRecords" (
                  "id"                TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "hkWorkoutId"       TEXT NOT NULL,
                  "points"            INTEGER NOT NULL,
                  "workoutStartDate"  TEXT NOT NULL,
                  "secondsZone1"      REAL NOT NULL,
                  "secondsZone2"      REAL NOT NULL,
                  "secondsZone3"      REAL NOT NULL,
                  "secondsZone4"      REAL NOT NULL,
                  "secondsZone5"      REAL NOT NULL,
                  "weightsVersion"    INTEGER NOT NULL,
                  "createdAt"         TEXT NOT NULL,
                  "updatedAt"         TEXT NOT NULL,
                  "ckRecordData"      BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE UNIQUE INDEX "index_workoutEffortScoreRecords_on_hkWorkoutId"
                ON "workoutEffortScoreRecords"("hkWorkoutId")
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_workoutEffortScoreRecords_on_workoutStartDate"
                ON "workoutEffortScoreRecords"("workoutStartDate")
                """)
            .execute(db)
        }

        // GymClass gains a geocoded address (latitude/longitude, nullable — filled
        // from the MapKit address picker) and a weekly-recurrence flag. Existing
        // rows decode fine: coordinates stay NULL, isRecurring defaults to 0.
        migrator.registerMigration("v10_gymClassLocationAndRecurrence") { db in
            try #sql("""
                ALTER TABLE "gymClassRecords" ADD COLUMN "latitude" REAL
                """)
            .execute(db)
            try #sql("""
                ALTER TABLE "gymClassRecords" ADD COLUMN "longitude" REAL
                """)
            .execute(db)
            try #sql("""
                ALTER TABLE "gymClassRecords" ADD COLUMN "isRecurring" INTEGER NOT NULL DEFAULT 0
                """)
            .execute(db)
        }

        // Participant's attendance of a GymRoom class (IOS-00104-C), linked 1:1 to the
        // workout via hkWorkoutId. Separate from effort score (attendance shows even for
        // a zero-point class). Coordinates nullable (class had no geocoded address).
        migrator.registerMigration("v11_classParticipation") { db in
            try #sql("""
                CREATE TABLE "classParticipationRecords" (
                  "id"                TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "hkWorkoutId"       TEXT NOT NULL,
                  "classSessionId"    TEXT NOT NULL,
                  "gymName"           TEXT NOT NULL DEFAULT '',
                  "place"             INTEGER NOT NULL,
                  "participantCount"  INTEGER NOT NULL,
                  "classPoints"       INTEGER NOT NULL,
                  "latitude"          REAL,
                  "longitude"         REAL,
                  "createdAt"         TEXT NOT NULL,
                  "updatedAt"         TEXT NOT NULL,
                  "ckRecordData"      BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE UNIQUE INDEX "index_classParticipationRecords_on_hkWorkoutId"
                ON "classParticipationRecords"("hkWorkoutId")
                """)
            .execute(db)
        }

        // PR Board result entries (S-02). Loose relation to the static PR catalog
        // via movementId; duplicates per movement+day are allowed by design —
        // ties are resolved by PRResolver (date, then createdAt).
        migrator.registerMigration("v12_prEntries") { db in
            try #sql("""
                CREATE TABLE "prEntryRecords" (
                  "id"            TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE,
                  "movementId"    TEXT NOT NULL,
                  "date"          TEXT NOT NULL,
                  "scoreType"     TEXT NOT NULL,
                  "weightKg"      REAL,
                  "timeSeconds"   INTEGER,
                  "rounds"        INTEGER,
                  "extraReps"     INTEGER,
                  "isRx"          INTEGER,
                  "equipment"     TEXT NOT NULL DEFAULT '',
                  "rpe"           REAL,
                  "note"          TEXT,
                  "bodyWeightKg"  REAL,
                  "context"       TEXT NOT NULL,
                  "createdAt"     TEXT NOT NULL,
                  "updatedAt"     TEXT NOT NULL,
                  "ckRecordData"  BLOB
                ) STRICT
                """)
            .execute(db)
            try #sql("""
                CREATE INDEX "index_prEntryRecords_on_movementId"
                ON "prEntryRecords"("movementId")
                """)
            .execute(db)
        }

        return migrator
    }
}
