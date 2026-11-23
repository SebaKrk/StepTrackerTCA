//
//  WatchContextKey.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import Foundation

/// Keys used in the `WCSession` application context dictionary.
///
/// `updateApplicationContext` replaces the ENTIRE dictionary on every call.
/// Any future producer must merge into the existing context rather than
/// overwrite it, or it will silently drop the other keys.
public enum WatchContextKey {

    /// Holds a JSON-encoded `ReadinessSnapshot`.
    public static let readinessSnapshot = "readinessSnapshot"

    /// Holds `true` when readiness needs Pro; sent instead of a snapshot.
    public static let readinessLocked = "readinessLocked"

    /// Holds a `Bool`: whether the iPhone's user wants workout logs recorded.
    public static let workoutLogRecording = "workoutLogRecording"
}
