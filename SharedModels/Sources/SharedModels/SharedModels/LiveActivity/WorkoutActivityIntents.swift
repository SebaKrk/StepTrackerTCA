//
//  WorkoutActivityIntents.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 2026-05-28.
//

#if canImport(ActivityKit) && !os(macOS)
import ActivityKit
import AppIntents
import Foundation

// MARK: - Notification bridge

/// Notifications posted by Live Activity intents (running in main app process via
/// `openAppWhenRun = true`). `SessionFeature` subscribes to these in its long-running
/// effects and dispatches the corresponding TCA actions, reusing the existing
/// pause/resume/end flow (HKWorkoutSession + WC + retry).
public extension Notification.Name {
    static let workoutPauseRequested = Notification.Name("workoutPauseRequested")
    static let workoutResumeRequested = Notification.Name("workoutResumeRequested")
    static let workoutEndRequested = Notification.Name("workoutEndRequested")
}

// MARK: - Pause / Resume / End intents

/// Lock Screen + Dynamic Island button — pauses the active workout.
///
/// `openAppWhenRun = true` brings the main app to the foreground so `perform()` runs
/// inside the app's process — required because `HKWorkoutSession.pause()` lives in
/// `HealthHub` (not reachable from the widget extension's @Dependency graph).
/// The intent posts a NotificationCenter event; `SessionFeature` observer dispatches
/// the existing TCA pause action — reusing the same flow as the on-screen control.
public struct PauseWorkoutIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Pause Workout"
    public static var openAppWhenRun: Bool { true }

    public init() {}

    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .workoutPauseRequested, object: nil)
        return .result()
    }
}

/// Lock Screen + Dynamic Island button — resumes a paused workout. See `PauseWorkoutIntent`.
public struct ResumeWorkoutIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Resume Workout"
    public static var openAppWhenRun: Bool { true }

    public init() {}

    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .workoutResumeRequested, object: nil)
        return .result()
    }
}

/// Lock Screen + Dynamic Island button — ends the active workout.
///
/// Posts `workoutEndRequested` which `SessionFeature` routes to the same
/// `controls(.view(.endWorkoutButtonTapped))` handler used by the on-screen End button —
/// including the HK-channel `.workoutEnded` send to Watch in Watch-primary mode.
public struct EndWorkoutIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "End Workout"
    public static var openAppWhenRun: Bool { true }

    public init() {}

    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .workoutEndRequested, object: nil)
        return .result()
    }
}
#endif
