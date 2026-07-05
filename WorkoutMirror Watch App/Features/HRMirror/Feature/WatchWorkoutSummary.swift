//
//  WatchWorkoutSummary.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Ściuba on 03/07/2026.
//

import Foundation

/// Snapshot of the just-saved `HKWorkout` shown on the Watch mini-summary (IOS-00098-D).
///
/// Built by `WatchWorkoutSessionManager` directly from the `finishWorkout()` return
/// value — no HealthKit re-fetch, following Apple's iOS 26 sample pattern where the
/// primary device feeds its summary from the in-memory workout.
///
/// `nonisolated` — crosses the `@Sendable` closure boundary of
/// `WatchWorkoutSessionClient.consumeLastSavedWorkoutSummary`; under
/// `defaultIsolation(MainActor.self)` the synthesized conformances would otherwise
/// be main-actor-isolated and fail the `Sendable` requirement.
nonisolated struct WatchWorkoutSummary: Equatable, Sendable {

    /// Total workout duration (pauses excluded — `HKWorkout.duration` semantics).
    let duration: TimeInterval

    /// Active energy burned during the workout, in kilocalories.
    let activeEnergyKcal: Double

    /// Average heart rate over the workout, in beats per minute.
    let averageHeartRate: Double
}
