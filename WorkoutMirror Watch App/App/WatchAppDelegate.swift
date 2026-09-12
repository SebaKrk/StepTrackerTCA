//
//  WatchAppDelegate.swift
//  WorkoutMirror Watch App
//

import ComposableArchitecture
import HealthKit
import OSLog
import SharedModels
import WatchKit

/// `WKApplicationDelegate` that handles HealthKit workout configuration
/// forwarded from the paired iPhone via `HKHealthStore.startWatchApp(toHandle:)`.
///
/// When iPhone calls `startWatchApp(toHandle:)`, watchOS delivers the workout
/// configuration here **before** the SwiftUI scene is fully rendered. Yielding
/// the activity type to `WorkoutConfigurationStream` allows `AppFeatureAW` to
/// react and start `HRMirrorFeature` — which in turn calls
/// `startMirroringToCompanionDevice()`, automatically bringing the app to the
/// foreground.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {

    @Dependency(\.watchWorkoutSessionClient) private var watchWorkoutSessionClient

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Logger.appAW.info("[WatchAppDelegate] handle(_:) — activityType: \(workoutConfiguration.activityType.rawValue), locationType: \(workoutConfiguration.locationType.rawValue)")
        WorkoutConfigurationStream.shared.yield(
            .init(
                activityType: workoutConfiguration.activityType,
                locationType: workoutConfiguration.locationType
            )
        )
    }

    /// Called when the system relaunches the app after a crash during an active
    /// `HKWorkoutSession`. May fire in the background, before any scene renders,
    /// so recovery cannot wait for the reducer's launch check — it runs here directly.
    /// `recoverStuckSession` is single-flight, so overlapping with that check is safe.
    func handleActiveWorkoutRecovery() {
        Logger.appAW.notice("[WatchAppDelegate] handleActiveWorkoutRecovery — relaunched after crash mid-workout")
        Task { [watchWorkoutSessionClient] in
            _ = await watchWorkoutSessionClient.recoverStuckSession()
        }
    }
}
