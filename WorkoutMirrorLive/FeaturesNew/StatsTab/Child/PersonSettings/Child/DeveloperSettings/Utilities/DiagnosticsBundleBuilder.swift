//
//  DiagnosticsBundleBuilder.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Foundation

/// Assembles the folder that becomes the diagnostics archive.
enum DiagnosticsBundleBuilder {

    /// Creates an empty, date-stamped folder in the temporary directory.
    ///
    /// - Parameter date: Timestamp used in the folder name
    /// - Returns: URL of the created folder
    /// - Throws: File system errors if the folder cannot be created
    nonisolated static func makeFolder(stampedWith date: Date) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"

        let folder = FileManager.default.temporaryDirectory
            .appending(path: namePrefix + formatter.string(from: date))

        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        return folder
    }

    /// Copies files into a folder inside the bundle; nothing is created when the list is empty.
    ///
    /// - Parameters:
    ///   - files: The files to copy
    ///   - folder: Destination folder, created if needed
    /// - Throws: File system errors if a copy fails
    nonisolated static func copy(_ files: [URL], into folder: URL) throws {
        guard !files.isEmpty else { return }

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for file in files {
            try FileManager.default.copyItem(at: file, to: folder.appending(path: file.lastPathComponent))
        }
    }

    /// Deletes every diagnostics archive and working folder in the temporary directory.
    nonisolated static func removeLeftovers() {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: FileManager.default.temporaryDirectory,
            includingPropertiesForKeys: nil
        )

        for item in contents ?? [] where item.lastPathComponent.hasPrefix(namePrefix) {
            try? FileManager.default.removeItem(at: item)
        }
    }

    /// Start of every diagnostics folder and archive name; what `removeLeftovers` looks for.
    nonisolated private static let namePrefix = "MyFitnessJournal-diagnostics-"

    /// Zips a folder and returns the archive, which outlives this call.
    ///
    /// - Parameter folder: The folder to compress
    /// - Returns: URL of the archive, as a sibling of `folder`
    /// - Throws: Coordination or file system errors
    nonisolated static func zip(_ folder: URL) throws -> URL {
        var archive: URL?
        var failure: Error?
        var coordinationError: NSError?

        NSFileCoordinator().coordinate(
            readingItemAt: folder,
            options: [.forUploading],
            error: &coordinationError
        ) { temporary in
            // The coordinator deletes its own zip as soon as this closure
            // returns, so it has to be moved out before that happens.
            let destination = folder
                .deletingLastPathComponent()
                .appending(path: folder.lastPathComponent + ".zip")

            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: temporary, to: destination)
                archive = destination
            } catch {
                failure = error
            }
        }

        if let coordinationError { throw coordinationError }
        if let failure { throw failure }

        guard let archive else { throw DiagnosticsBundleError.archiveMissing }

        return archive
    }
}
