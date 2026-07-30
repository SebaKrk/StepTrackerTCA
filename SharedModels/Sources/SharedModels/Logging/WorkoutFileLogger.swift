//
//  WorkoutFileLogger.swift
//  SharedModels
//

import Foundation
import OSLog

/// Writes timestamped workout events to a plain-text file in the app's
/// Documents directory. Accessible in Files.app after a workout without a Mac.
///
/// Used by both Watch and iPhone targets — file prefix differs per platform:
/// - watchOS → `watch_log_<timestamp>.txt`
/// - iOS     → `iphone_log_<timestamp>.txt`
///
/// HR readings are throttled to one entry per 30 seconds to keep the file readable.
public actor WorkoutFileLogger {

    public static let shared = WorkoutFileLogger()

    // MARK: - Private

    private var startDate: Date = Date()

    private var fileURL: URL {
        let timestamp = Int(startDate.timeIntervalSince1970)
        #if os(watchOS)
        let prefix = "watch"
        #else
        let prefix = "iphone"
        #endif
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(prefix)_log_\(timestamp).txt")
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var lastHRLogDate: Date = .distantPast
    private let hrLogInterval: TimeInterval = 30

    // MARK: - Public API

    /// Clears the log file and writes a header. Call at workout start.
    /// Debug builds only — no-op in release.
    public func reset() {
        #if DEBUG
        startDate = Date()
        let header = "=== Workout Log \(startDate) ===\n"
        try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        lastHRLogDate = .distantPast
        #endif
    }

    /// Appends a timestamped line to the log file.
    /// Debug builds only — no-op in release.
    public func log(_ message: String) {
        #if DEBUG
        let time = timeFormatter.string(from: Date())
        let line = "[\(time)] \(message)\n"
        append(line)
        #endif
    }

    /// Logs an HR reading, but at most once every 30 seconds.
    /// Debug builds only — no-op in release.
    public func logHRIfNeeded(bpm: Double) {
        #if DEBUG
        let now = Date()
        guard now.timeIntervalSince(lastHRLogDate) >= hrLogInterval else { return }
        lastHRLogDate = now
        log("HR: \(Int(bpm)) bpm")
        #endif
    }

    /// Returns the URL of the current log file.
    public func currentFileURL() -> URL { fileURL }

    // MARK: - Private

    private func append(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: fileURL)
        }
    }
}
