//
//  WatchWorkoutEvent.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import Foundation

/// Events exchanged between iPhone and Apple Watch via WatchConnectivity.
///
/// **iPhone → Watch:** `workoutStarted`, `workoutPaused`, `workoutResumed`, `workoutEnded`, `workoutTick`, `maxHRUpdated`
/// **Watch → iPhone:** `workoutSaved`
///
/// Note: HR readings flow via HealthKit mirroring channel (`sendToRemoteWorkoutSession`),
/// NOT WatchConnectivity — per WWDC25 #322 R2.
public enum WatchWorkoutEvent: Codable, Sendable, Equatable {

    /// iPhone notifies Watch that a workout has started.
    /// - Parameters:
    ///   - activityType: Raw value of `HKWorkoutActivityType`.
    ///   - elapsedSeconds: Seconds already elapsed at the time of sending (typically 0).
    ///   - maxHeartRate: User's calculated maximum heart rate — Watch needs this to calculate HR zones.
    case workoutStarted(activityType: UInt, elapsedSeconds: TimeInterval, maxHeartRate: Int)

    /// iPhone notifies Watch that the workout has been paused.
    case workoutPaused

    /// iPhone notifies Watch that the workout has been resumed.
    /// - Parameter elapsedSeconds: Elapsed seconds at the moment of resumption.
    case workoutResumed(elapsedSeconds: TimeInterval)

    /// iPhone notifies Watch that the workout has ended.
    case workoutEnded

    /// iPhone notifies Watch that the pre-workout 3-2-1 countdown has just started.
    ///
    /// Sent when iPhone transitions `.waitingForWatch` → `.countdown` (after Watch's
    /// mirrored session signal arrives). Watch displays a synced 3-2-1 number overlay
    /// until either its local timer reaches zero or `countdownFinished` arrives.
    case countdownStart

    /// iPhone notifies Watch that the pre-workout countdown has finished.
    ///
    /// Watch uses this as the signal to start its elapsed-time timer.
    /// This eliminates the need for an independent countdown on Watch,
    /// which would drift due to WatchConnectivity delivery latency.
    case countdownFinished

    /// iPhone sends the authoritative elapsed time to Watch once per second.
    ///
    /// Watch displays this value directly — it has no local timer.
    /// - Parameter elapsedSeconds: Current elapsed seconds on the iPhone workout clock.
    case workoutTick(elapsedSeconds: TimeInterval)

    /// iPhone sends the user's calculated max heart rate after HealthKit lookup completes.
    ///
    /// Sent when the value becomes available after `workoutStarted` — Watch updates its
    /// zone calculation immediately on receipt.
    case maxHRUpdated(Int)

    /// Watch notifies iPhone that `finishWorkout()` succeeded and the `HKWorkout`
    /// is now persisted in HealthKit. iPhone can begin fetching the summary by UUID.
    ///
    /// - Parameter workoutUUID: UUID of the saved HKWorkout. iPhone uses this to fetch
    ///   the exact workout via `HKQuery.predicateForObject(with:)` without race-prone
    ///   timestamp-based predicates.
    ///
    /// Sent after `WatchWorkoutSessionClient.endSession()` completes successfully (either
    /// via primary path or `.ended` safety-net). If this event is not received (e.g. Watch
    /// unreachable), iPhone falls back to HealthKit polling after a timeout.
    case workoutSaved(workoutUUID: UUID)
}
