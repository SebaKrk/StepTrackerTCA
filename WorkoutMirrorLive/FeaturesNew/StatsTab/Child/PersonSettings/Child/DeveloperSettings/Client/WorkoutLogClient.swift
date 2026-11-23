//
//  WorkoutLogClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 23/11/2026.
//

import Foundation

/// TCA dependency over the workout log files; the files themselves are `WorkoutLogStore`'s business.
struct WorkoutLogClient: Sendable {

    /// Whether workout logs are being recorded: always in debug builds, the user's choice in release.
    var isRecording: @Sendable () -> Bool

    /// Every workout log currently on the iPhone, the Watch's delivered ones included.
    var logFiles: @Sendable () -> [URL]

    /// Deletes logs that are too old or beyond the limit, measured against the given time.
    var prune: @Sendable (_ now: Date) async -> Void

    /// Deletes every workout log on the iPhone.
    var removeAll: @Sendable () async -> Void
}
