//
//  WatchAppDelegate.swift
//  WorkoutMirror Watch App
//

import WatchKit
import HealthKit

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

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        print("⌚ [WatchAppDelegate] handle(_:) — activityType: \(workoutConfiguration.activityType.rawValue)")
        WorkoutConfigurationStream.shared.yield(workoutConfiguration.activityType)
    }
}
