//
//  LiveActivityStaleness.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

/// When a Live Activity's numbers stop being worth believing.
///
/// Shared by both activity clients: a session shows either banner, and the two
/// drifting apart would mean one of them keeps presenting frozen data as live.
enum LiveActivityStaleness {

    /// How long an activity's content stays trustworthy after an update.
    ///
    /// Metrics arrive with every heart-rate sample, so a running workout refreshes every
    /// few seconds and never comes close to this. The window exists for the quiet
    /// stretches that are not failures: HealthKit's batching while the app is suspended,
    /// and a pause — the builder stops collecting then, so a rest looks exactly like
    /// silence. A pause longer than this window still reads as lost data, because the
    /// content state carries no `isPaused` to say otherwise.
    static let tolerance: TimeInterval = 900

    /// The moment the content being written now stops being trustworthy.
    static var date: Date {
        Date().addingTimeInterval(tolerance)
    }
}
