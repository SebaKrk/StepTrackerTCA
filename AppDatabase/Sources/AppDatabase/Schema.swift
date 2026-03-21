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

        try migrator.migrate(database)
        defaultDatabase = database

        #if DEBUG
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        print("📦 [AppDatabase] path: \(appSupport?.path ?? "unknown")")
        #endif
    }
}
