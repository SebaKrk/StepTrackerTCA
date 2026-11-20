//
//  DatabaseSnapshotReader.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Foundation
import SQLiteData

/// Describes the shape of the database — which migrations ran and how much sits
/// in each table — without reading a single row of content.
enum DatabaseSnapshotReader {

    /// Reads schema state and row counts.
    ///
    /// - Parameter db: An open database connection
    /// - Returns: Report lines, ready to join
    /// - Throws: Database errors if the table list cannot be read
    static func read(_ db: Database) throws -> [String] {
        var lines = ["BAZA DANYCH", "-----------"]

        // A missing migrations table means a database built before the migrator,
        // which is itself worth seeing in the report rather than throwing on.
        let migrations = (try? #sql(
            "SELECT identifier FROM grdb_migrations ORDER BY rowid",
            as: String.self
        ).fetchAll(db)) ?? []

        lines.append("Zastosowane migracje: \(migrations.count)")
        lines.append("Ostatnia migracja:    \(migrations.last ?? "brak")")
        lines.append("")
        lines.append("Liczba wierszy:")

        let tables = try #sql(
            """
            SELECT name FROM sqlite_master
            WHERE type = 'table'
              AND name NOT LIKE 'sqlite_%'
              AND name NOT LIKE 'grdb_%'
            ORDER BY name
            """,
            as: String.self
        ).fetchAll(db)

        for table in tables {
            lines.append("  \(padded(table)) \(count(of: table, in: db))")
        }

        return lines
    }

    // MARK: - Private Methods

    /// Row count, or a marker when the table cannot be counted.
    private static func count(of table: String, in db: Database) -> String {
        let identifier = "\"" + table.replacingOccurrences(of: "\"", with: "\"\"") + "\""

        guard let value = try? #sql(
            "SELECT COUNT(*) FROM \(raw: identifier)",
            as: Int.self
        ).fetchOne(db) else {
            return "?"
        }

        return "\(value)"
    }

    /// Pads a table name so the counts line up in a plain-text viewer.
    private static func padded(_ name: String) -> String {
        name.count >= 30 ? name : name + String(repeating: " ", count: 30 - name.count)
    }
}
