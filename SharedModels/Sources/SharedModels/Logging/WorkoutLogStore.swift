//
//  WorkoutLogStore.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 23/11/2026.
//

import Foundation

/// Knows where the workout log files live: names them, lists them, prunes old ones and removes them all.
public enum WorkoutLogStore {

    // MARK: - Limits

    /// Workout logs kept per device; older ones are deleted.
    public static let workoutLogLimit = 10

    /// Idle logs kept per device; they only cover the time between workouts.
    public static let idleLogLimit = 3

    /// Logs older than this are deleted whatever their count.
    public static let maximumAge: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - Recording

    /// Whether events are written: always in debug builds, the user's choice in release.
    public static var isRecordingEnabled: Bool {
        #if DEBUG
        true
        #else
        UserDefaults.standard.bool(forKey: AppStorageKeys.workoutLogRecording)
        #endif
    }

    // MARK: - Location

    /// Folder holding the logs — outside Documents, so Files.app and iCloud backup never see them.
    public static var directory: URL { preparedDirectory }

    /// Name of a log file; the start time is part of it, so no file date has to be read later.
    public static func fileURL(devicePrefix: String, isIdle: Bool, startedAt: Date) -> URL {
        let kind = isIdle ? idleMarker : workoutMarker
        let timestamp = Int(startedAt.timeIntervalSince1970)
        return directory.appendingPathComponent("\(devicePrefix)\(kind)\(timestamp).\(fileExtension)")
    }

    // MARK: - Files

    /// Every log file in the folder, in no particular order.
    public static func logFiles() -> [URL] {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        return (contents ?? []).filter(isLogFile)
    }

    /// Deletes logs that are too old or beyond the per-device limit; `current` is never touched.
    ///
    /// Internal on purpose: callers go through `WorkoutFileLogger`, which knows the file being written.
    static func prune(now: Date, keeping current: URL?) {
        removeLegacyLogs()
        let groups = Dictionary(grouping: logFiles(), by: groupName)
        for (group, files) in groups {
            let limit = group.hasSuffix(idleMarker) ? idleLogLimit : workoutLogLimit
            let newestFirst = files.sorted { startDate(of: $0) > startDate(of: $1) }
            for (index, file) in newestFirst.enumerated()
            where file.lastPathComponent != current?.lastPathComponent {
                let isTooOld = now.timeIntervalSince(startDate(of: file)) > maximumAge
                if index >= limit || isTooOld {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }

    /// Deletes every log — turning recording off must leave nothing behind.
    ///
    /// Internal on purpose: callers go through `WorkoutFileLogger`, so no line in flight brings a file back.
    static func removeAll() {
        removeLegacyLogs()
        let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        // The whole folder, not only finished logs: a half-received copy must go too.
        for file in contents ?? [] {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Private

    /// Part of a workout log's name between the device prefix and the timestamp.
    private static let workoutMarker = "_log_"

    /// Part of an idle log's name between the device prefix and the timestamp.
    private static let idleMarker = "_idle_log_"

    /// Extension of every log file.
    private static let fileExtension = "txt"

    /// Created once per launch; the folder is excluded from backups.
    private static let preparedDirectory: URL = {
        var folder = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WorkoutLogs", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
        return folder
    }()

    /// Whether the file follows the log naming, so nothing else in the folder is ever touched.
    private static func isLogFile(_ url: URL) -> Bool {
        url.pathExtension == fileExtension && url.lastPathComponent.contains(workoutMarker)
    }

    /// Name without the timestamp — the device and the kind, e.g. `watch_idle_log_`.
    private static func groupName(of url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        guard let separator = name.lastIndex(of: "_") else { return name }
        return String(name[...separator])
    }

    /// Start time read from the name; a file without one counts as the oldest.
    private static func startDate(of url: URL) -> Date {
        let name = url.deletingPathExtension().lastPathComponent
        guard let separator = name.lastIndex(of: "_"),
              let timestamp = TimeInterval(name[name.index(after: separator)...])
        else { return .distantPast }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Logs written by earlier builds sat in Documents, visible in Files.app.
    private static func removeLegacyLogs() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let contents = try? FileManager.default.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: nil
        )
        for file in contents ?? [] {
            let name = file.lastPathComponent
            let isLegacyLog = name.hasPrefix("iphone_log_") || name.hasPrefix("watch_log_")
            if isLegacyLog, file.pathExtension == fileExtension {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
