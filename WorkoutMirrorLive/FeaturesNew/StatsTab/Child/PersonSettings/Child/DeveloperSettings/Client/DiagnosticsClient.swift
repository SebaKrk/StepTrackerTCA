//
//  DiagnosticsClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Dependencies
import Foundation
import MessageUI
import OSLog
import SQLiteData

struct DiagnosticsClient: Sendable {

    /// Builds a zip in the temporary directory and returns its URL.
    ///
    /// The report alone carries no personal data. Workout logs ride along while
    /// recording is on — they hold heart rate. Passing `true` adds a copy of the
    /// database, which holds the full training history and the profile.
    var makeBundle: @Sendable (_ includesDatabase: Bool) async throws -> URL

    /// Deletes every diagnostics archive and working folder left in the temporary directory.
    var discardBundles: @Sendable () -> Void

    /// Whether the device can send mail, deciding between the pre-addressed
    /// composer and the share sheet.
    ///
    /// Main-actor bound because `MFMailComposeViewController` is.
    var canSendMail: @MainActor @Sendable () -> Bool
}

extension DependencyValues {

    var diagnosticsClient: DiagnosticsClient {
        get { self[DiagnosticsClientKey.self] }
        set { self[DiagnosticsClientKey.self] = newValue }
    }
}

/// Diagnostic logger for the bundle pipeline (DEBUG-only call sites).
private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "WorkoutMirrorLive",
    category: "Diagnostics"
)

private enum DiagnosticsClientKey: DependencyKey {

    static let liveValue = DiagnosticsClient(
        makeBundle: { includesDatabase in
            @Dependency(\.defaultDatabase) var database
            @Dependency(\.date.now) var now
            @Dependency(\.workoutLogClient) var workoutLogClient

            // Earlier archives can hold heart rate or the database; none may outlive the next one.
            DiagnosticsBundleBuilder.removeLeftovers()

            let folder = try DiagnosticsBundleBuilder.makeFolder(stampedWith: now)
            // Only the zip leaves this call; the unzipped copy would otherwise stay behind.
            defer { try? FileManager.default.removeItem(at: folder) }

            let report = try await DiagnosticsReport.make(reading: database, at: now)
            try report.write(
                to: folder.appending(path: "report.txt"),
                atomically: true,
                encoding: .utf8
            )

            // Checked here too: a log written just before the switch went off must not travel.
            if workoutLogClient.isRecording() {
                // Pruned first, so the bundle never carries a log past its retention.
                await workoutLogClient.prune(now)
                try DiagnosticsBundleBuilder.copy(
                    workoutLogClient.logFiles(),
                    into: folder.appending(path: "logs")
                )
            }

            if includesDatabase {
                // VACUUM INTO, not a file copy: the write-ahead log holds recent
                // changes that a plain copy of the .db would silently leave out.
                let copy = folder.appending(path: "database.sqlite")
                    .path(percentEncoded: false)
                    .replacingOccurrences(of: "'", with: "''")

                // Outside a transaction on purpose: VACUUM cannot run inside one.
                try await database.writeWithoutTransaction { db in
                    try #sql("VACUUM INTO '\(raw: copy)'").execute(db)
                }
            }

            let archive = try DiagnosticsBundleBuilder.zip(folder)

            #if DEBUG
            logger.debug("[Diagnostics] bundle ready at \(archive.lastPathComponent)")
            #endif

            return archive
        },
        discardBundles: {
            DiagnosticsBundleBuilder.removeLeftovers()
        },
        canSendMail: { MFMailComposeViewController.canSendMail() }
    )

    static var previewValue: DiagnosticsClient {
        DiagnosticsClient(
            makeBundle: { _ in URL(fileURLWithPath: "/tmp/diagnostics-preview.zip") },
            discardBundles: {},
            canSendMail: { false }
        )
    }

    static var testValue: DiagnosticsClient {
        DiagnosticsClient(
            makeBundle: unimplemented("DiagnosticsClient.makeBundle"),
            discardBundles: unimplemented("DiagnosticsClient.discardBundles"),
            canSendMail: unimplemented("DiagnosticsClient.canSendMail", placeholder: false)
        )
    }
}
