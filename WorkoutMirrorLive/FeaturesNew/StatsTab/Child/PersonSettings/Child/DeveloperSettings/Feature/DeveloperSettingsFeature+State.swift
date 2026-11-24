//
//  DeveloperSettingsFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `DeveloperSettingsFeature` state
extension DeveloperSettingsFeature {

    @ObservableState
    struct State {

        // MARK: - Properties

        /// Whether the next diagnostics bundle carries a copy of the database.
        ///
        /// Off by default — the report alone describes the install without
        /// exposing anyone's training history.
        var includesDatabaseInDiagnostics = false

        /// The user's choice to record workout logs; release builds write nothing without it.
        @Shared(.appStorage(.workoutLogRecording))
        var isRecordingWorkoutLogs = false

        /// Debug builds always record, so there the switch is shown on and cannot be changed.
        var isWorkoutLogRecordingForced: Bool {
            #if DEBUG
            true
            #else
            false
            #endif
        }

        /// Whether the next diagnostics bundle carries workout logs.
        var attachesWorkoutLogs: Bool {
            isRecordingWorkoutLogs || isWorkoutLogRecordingForced
        }

        /// Whether a diagnostics bundle is being built right now.
        var isBuildingDiagnostics = false

        /// Archive waiting in the pre-addressed mail composer, or `nil`.
        var diagnosticsMailURL: URL?

        /// Archive waiting in the share sheet, used when the device has no mail
        /// account — the composer would refuse to open at all.
        var diagnosticsShareURL: URL?
    }
}
