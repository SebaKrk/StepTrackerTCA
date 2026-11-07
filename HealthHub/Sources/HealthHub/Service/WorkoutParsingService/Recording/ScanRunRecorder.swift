//
//  ScanRunRecorder.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 07/11/2026.
//

import Foundation
import SharedModels

#if DEBUG

/// Dumps every scan to `Documents/Diagnostics/ScanRuns/<timestamp>/` so a bad
/// parse can still be inspected once the app has moved on.
///
/// `UIFileSharingEnabled` already exposes `Documents`, so the folders are
/// reachable from the Files app without a cable. An actor, so the write never
/// lands on the main thread.
public actor ScanRunRecorder {

    // MARK: - Constants

    /// Keeps the dumps apart from the loose diagnostic files sitting in `Documents`.
    private static let diagnosticsFolder = "Diagnostics"

    /// Holds one subfolder per recorded scan.
    private static let scanRunsFolder = "ScanRuns"

    /// Colons are not safe in a folder name, so the ISO time separator is a dash.
    private static let folderFormat = "yyyy-MM-dd'T'HH-mm-ss"

    // MARK: - Properties

    /// Directory the per-scan folders are created in.
    private let root: URL

    // MARK: - Initialization

    public init(root: URL? = nil) {
        self.root = root ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(component: Self.diagnosticsFolder)
            .appending(component: Self.scanRunsFolder)
    }

    // MARK: - Recording

    /// Writes the scan input next to what the model made of it.
    ///
    /// Never throws: a failed dump must not take down the user's scan.
    public func record(
        _ input: WorkoutScanInput,
        backend: WorkoutParsingBackend,
        outcome: ScanRunOutcome,
        startedAt: Date,
        finishedAt: Date
    ) {
        do {
            let folder = root.appending(component: Self.folderName(for: startedAt))
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            // Re-run the downscaler so the dump holds the exact bytes the model was sent.
            if let imageData = input.imageData {
                let jpeg = try ScanImageDownscaler.jpeg(from: imageData)
                try jpeg.write(to: folder.appending(component: "input.jpg"))
            }

            if backend.needsOCRText, !input.ocrText.isEmpty {
                try Data(input.ocrText.utf8).write(to: folder.appending(component: "ocr.txt"))
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601

            if case let .success(board) = outcome {
                try encoder.encode(board).write(to: folder.appending(component: "board.json"))
            }

            let metadata = Self.metadata(
                input,
                backend: backend,
                outcome: outcome,
                startedAt: startedAt,
                finishedAt: finishedAt
            )
            try encoder.encode(metadata).write(to: folder.appending(component: "meta.json"))

            print("🗂️ [ScanRunRecorder] saved \(Self.diagnosticsFolder)/\(Self.scanRunsFolder)/\(folder.lastPathComponent)")
        } catch {
            print("⚠️ [ScanRunRecorder] dump failed: \(error)")
        }
    }

    // MARK: - Helpers

    private static func folderName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = folderFormat
        return formatter.string(from: date)
    }

    private static func metadata(
        _ input: WorkoutScanInput,
        backend: WorkoutParsingBackend,
        outcome: ScanRunOutcome,
        startedAt: Date,
        finishedAt: Date
    ) -> ScanRunMetadata {
        let board: ScannedBoard? = switch outcome {
        case let .success(value): value
        case .failure: nil
        }
        let failure: String? = switch outcome {
        case .success: nil
        case let .failure(description): description
        }

        return ScanRunMetadata(
            startedAt: startedAt,
            durationMs: Int(finishedAt.timeIntervalSince(startedAt) * 1000),
            backend: backend.rawValue,
            imageBytes: input.imageData?.count,
            ocrTextLength: input.ocrText.count,
            result: board == nil ? "failure" : "success",
            error: failure,
            sectionCount: board?.sections.count,
            movementCount: board?.sections.reduce(0) { $0 + $1.movements.count }
        )
    }
}

#endif
