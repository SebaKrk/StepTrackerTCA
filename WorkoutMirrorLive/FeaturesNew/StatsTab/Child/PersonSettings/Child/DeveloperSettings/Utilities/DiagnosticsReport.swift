//
//  DiagnosticsReport.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Foundation
import SQLiteData

/// Plain-text summary of the install, carrying no personal data.
///
/// Row counts and flags describe the shape of the data, never its content, so
/// the report can be sent on its own without sharing a training history.
enum DiagnosticsReport {

    /// Builds the report text.
    ///
    /// - Parameters:
    ///   - database: The database to describe
    ///   - date: Timestamp written into the header
    /// - Returns: The report as plain text
    /// - Throws: Database errors if the schema cannot be read
    static func make(reading database: any DatabaseWriter, at date: Date) async throws -> String {
        var lines: [String] = []

        lines.append("MyFitnessJournal — raport diagnostyczny")
        lines.append("=======================================")
        lines.append("Wygenerowany: \(date.formatted(.iso8601))")
        lines.append("")

        lines.append(contentsOf: installSection())
        lines.append("")

        let snapshot = try await database.read { db in
            try DatabaseSnapshotReader.read(db)
        }

        lines.append(contentsOf: snapshot)
        lines.append("")

        lines.append(contentsOf: flagsSection())

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Sections

    /// Identifies which of the parallel installs produced the bundle.
    private static func installSection() -> [String] {
        let info = Bundle.main.infoDictionary

        var machine = utsname()
        uname(&machine)
        let model = withUnsafePointer(to: &machine.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }

        return [
            "INSTALACJA",
            "----------",
            "Bundle ID:     \(Bundle.main.bundleIdentifier ?? "nieznany")",
            "Wersja:        \(info?["CFBundleShortVersionString"] as? String ?? "?")"
                + " (\(info?["CFBundleVersion"] as? String ?? "?"))",
            "System:        \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Urządzenie:    \(model)",
            "Język:         \(Locale.current.identifier)"
        ]
    }

    /// Versioned flags that live outside the database and explain most reports.
    private static func flagsSection() -> [String] {
        let defaults = UserDefaults.standard

        let nickname = defaults.string(forKey: "joinLiveClassNick") ?? ""

        return [
            "FLAGI",
            "-----",
            "Backfill gotowości:      \(defaults.integer(forKey: "readinessHistoryBackfilledVersion"))",
            "Re-match katalogu:       \(defaults.integer(forKey: "exerciseCatalogRematchVersion"))",
            "Plan subskrypcji:        \(defaults.string(forKey: "userSubscriptionTier") ?? "brak")",
            "Formuła maxHR:           \(defaults.string(forKey: "hrFormula") ?? "brak")",
            "Backend skanu planu:     \(defaults.string(forKey: "workoutParsingBackend") ?? "brak")",
            "Nick do Gym Roomu:       \(nickname.isEmpty ? "pusty" : "ustawiony")"
        ]
    }
}
