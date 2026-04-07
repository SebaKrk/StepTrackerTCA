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
/// **Watch → iPhone:** `hrReading`
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

    /// iPhone notifies Watch that the pre-workout countdown has finished.
    ///
    /// Watch uses this as the signal to start its elapsed-time timer.
    /// This eliminates the need for an independent countdown on Watch,
    /// which would drift due to WatchConnectivity delivery latency.
    case countdownFinished

    /// Watch sends a live heart rate reading back to iPhone.
    /// - Parameters:
    ///   - bpm: Heart rate in beats per minute.
    ///   - timestamp: Time of the measurement.
    case hrReading(bpm: Double, timestamp: Date)

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
}
