//
//  WorkoutLogClientKey.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/11/2026.
//

import Dependencies
import Foundation
import SharedModels

/// Registers `WorkoutLogClient` with the dependency system.
enum WorkoutLogClientKey: DependencyKey {

    /// Production client; file changes go through the logger so they cannot race a line being written.
    nonisolated static let liveValue = WorkoutLogClient(
        isRecording: { WorkoutLogStore.isRecordingEnabled },
        logFiles: { WorkoutLogStore.logFiles() },
        prune: { now in await WorkoutFileLogger.shared.prune(now: now) },
        removeAll: { await WorkoutFileLogger.shared.removeAll() }
    )

    /// Preview client with no files and nothing to delete.
    nonisolated static var previewValue: WorkoutLogClient {
        WorkoutLogClient(
            isRecording: { false },
            logFiles: { [] },
            prune: { _ in },
            removeAll: {}
        )
    }

    /// Test client that fails on any call a test did not override.
    nonisolated static var testValue: WorkoutLogClient {
        WorkoutLogClient(
            isRecording: unimplemented("WorkoutLogClient.isRecording", placeholder: false),
            logFiles: unimplemented("WorkoutLogClient.logFiles", placeholder: []),
            prune: unimplemented("WorkoutLogClient.prune"),
            removeAll: unimplemented("WorkoutLogClient.removeAll")
        )
    }
}

extension DependencyValues {

    /// Access to the workout log files.
    nonisolated var workoutLogClient: WorkoutLogClient {
        get { self[WorkoutLogClientKey.self] }
        set { self[WorkoutLogClientKey.self] = newValue }
    }
}
