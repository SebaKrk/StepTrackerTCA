//
//  WorkoutFileLogger.swift
//  SharedModels
//

import Foundation
import OSLog

/// Writes timestamped workout events to a plain-text file in `WorkoutLogStore.directory`.
///
/// Used by both Watch and iPhone targets — file prefix differs per platform:
/// - watchOS → `watch_log_<timestamp>.txt`
/// - iOS     → `iphone_log_<timestamp>.txt`
///
/// Lines logged before a workout starts go to a small `_idle_log_` file, so
/// app launches cannot push real workout logs out of the retention limit.
///
/// HR readings are throttled to one entry per 30 seconds to keep the file readable;
/// debug builds add a `[HR <stage>]` trace line for every reading at every stage.
public actor WorkoutFileLogger {

    public static let shared = WorkoutFileLogger()

    // MARK: - Private

    /// Start of the file being written; part of its name.
    private var startDate: Date = Date()

    /// `false` until a workout starts — lines before that go to an idle file.
    private var isWorkoutFile = false

    /// File the next line is appended to.
    private var fileURL: URL {
        WorkoutLogStore.fileURL(
            devicePrefix: Self.devicePrefix,
            isIdle: !isWorkoutFile,
            startedAt: startDate
        )
    }

    /// Tells the two devices' files apart once they sit in one folder on the iPhone.
    private static var devicePrefix: String {
        #if os(watchOS)
        "watch"
        #else
        "iphone"
        #endif
    }

    /// Formats the time in front of every line.
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Formats the time of a trace line; milliseconds show the delay between two stages.
    private let traceTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// When the last heart-rate line was written.
    private var lastHRLogDate: Date = .distantPast

    /// Shortest gap between two heart-rate lines.
    private let hrLogInterval: TimeInterval = 30

    /// Calls since the last heart-rate line; on the Watch that is how often the sensor reports.
    private var hrReadingsSinceLastLine = 0

    /// A workout file older than this is closed — nothing ends a workout file on the iPhone otherwise.
    private let workoutFileSpan: TimeInterval = 12 * 60 * 60

    /// An idle file older than this is replaced, so a long-lived app cannot grow one forever.
    private let idleFileSpan: TimeInterval = 24 * 60 * 60

    /// `true` once this launch pruned old logs; targets that never start a workout prune here.
    private var didPruneOnFirstWrite = false

    // MARK: - Public API

    /// Starts a new workout file with a header and prunes old logs. Call at workout start.
    public func reset() {
        guard WorkoutLogStore.isRecordingEnabled else { return }
        startDate = Date()
        isWorkoutFile = true
        let header = "=== Workout Log \(startDate) ===\n"
        try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        lastHRLogDate = .distantPast
        hrReadingsSinceLastLine = 0
        didPruneOnFirstWrite = true
        prune(now: startDate)
    }

    /// Appends a timestamped line to the log file.
    public func log(_ message: String) {
        guard WorkoutLogStore.isRecordingEnabled else { return }
        let now = Date()
        rotateFileIfNeeded(at: now)
        if !didPruneOnFirstWrite {
            didPruneOnFirstWrite = true
            prune(now: now)
        }
        let time = timeFormatter.string(from: now)
        let line = "[\(time)] \(message)\n"
        append(line)
    }

    /// Logs an HR reading, but at most once every 30 seconds.
    public func logHRIfNeeded(bpm: Double) {
        guard WorkoutLogStore.isRecordingEnabled else { return }
        let now = Date()
        hrReadingsSinceLastLine += 1
        guard now.timeIntervalSince(lastHRLogDate) >= hrLogInterval else { return }
        lastHRLogDate = now
        log("HR: \(Int(bpm)) bpm (\(hrReadingsSinceLastLine) readings)")
        hrReadingsSinceLastLine = 0
    }

    /// Writes one heart-rate reading at one stage of its way from the sensor to a screen.
    ///
    /// Debug builds only: every reading at every stage is too much for a user's log.
    /// `date` is taken by the caller, so the line shows when the stage happened, not when it was written.
    public func logHRTrace(stage: String, bpm: Double, at date: Date) {
        #if DEBUG
        guard WorkoutLogStore.isRecordingEnabled else { return }
        append("[\(traceTimeFormatter.string(from: date))] [HR \(stage)] \(Int(bpm)) bpm\n")
        #endif
    }

    /// Returns the URL of the current log file.
    public func currentFileURL() -> URL { fileURL }

    /// Closes the workout file and returns it; later lines go to a new idle file.
    ///
    /// A file handed out here is never written again, so it can be sent and deleted safely.
    public func sealCurrentFile() -> URL? {
        guard isWorkoutFile else { return nil }
        let sealed = fileURL
        startDate = Date()
        isWorkoutFile = false
        return FileManager.default.fileExists(atPath: sealed.path) ? sealed : nil
    }

    /// Deletes old logs; done inside the actor, so the file being written is never among them.
    public func prune(now: Date) {
        WorkoutLogStore.prune(now: now, keeping: fileURL)
    }

    /// Finished log files after pruning — listed inside the actor, so a file just started cannot slip in.
    public func finishedLogFiles(now: Date) -> [URL] {
        prune(now: now)
        let current = fileURL.lastPathComponent
        return WorkoutLogStore.logFiles().filter { $0.lastPathComponent != current }
    }

    /// Deletes every log; done inside the actor, so no line in flight can bring a file back.
    public func removeAll() {
        WorkoutLogStore.removeAll()
    }

    // MARK: - Private

    /// Moves on to a fresh idle file once the current file outlived its span.
    private func rotateFileIfNeeded(at now: Date) {
        let span = isWorkoutFile ? workoutFileSpan : idleFileSpan
        guard now.timeIntervalSince(startDate) > span else { return }
        startDate = now
        isWorkoutFile = false
    }

    private func append(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            // The throwing calls, not `seekToEndOfFile`/`write(_:)` — those raise on a full disk and crash.
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL)
        }
    }
}
