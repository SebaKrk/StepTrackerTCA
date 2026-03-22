//
//  Schema.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 21/03/2026.
//

import Dependencies
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
            try UserProfileRecord.createTable(db)
        }

        try migrator.migrate(database)
        defaultDatabase = database
    }
}
