//
//  WorkoutManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import HealthKit
import SharedModels

/// A protocol that manages HealthKit-based workout sessions.
///
/// This includes starting a workout, toggling pause/resume, ending the session,
/// and exposing real-time streams for workout metrics and session state.
///
@available(iOS 26.0, *)
public protocol WorkoutManager: Sendable {
    
    /// The current HKLiveWorkoutBuilder instance used to collect live workout data.
    ///
    /// This is exposed for internal use and should not be modified externally.
    var builder: HKLiveWorkoutBuilder? { get }
    
    // MARK: - Workout Configuration
    
    /// Sets the workout type and initializes a new HealthKit session.
    ///
    /// - Parameter type: The workout activity type to be tracked.
    func setSelectedWorkout(_ type: HKWorkoutActivityType?)

    /// Sets the state of the summary view (shown at the end of a workout).
    ///
    /// - Parameter value: `true` to show the summary view, `false` to hide it.
    func setValueForSummaryView(_ value: Bool)
    
    // MARK: - Session Lifecycle
    
    var sessionState: HKWorkoutSessionState { get }
    
    //func sessionStateStream() -> AsyncStream<HKWorkoutSessionState>
    
    /// Pauses or resumes the workout session depending on its current state.
    func togglePause()
    
    /// Ends the current workout session.
    func endWorkout()
    
    ///
    func startWorkout() async
    
    // MARK: - Streams
    
    /// A stream that emits live workout metrics, such as heart rate and calories burned.
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> { get }
    
    /// A stream that emits updates about the workout session's state.
    ///
    /// This stream emits values of type `HKWorkoutSessionState` whenever the state of the
    /// workout session changes (e.g., running, paused, ended).
    ///
    /// - Returns: An `AsyncStream` of `HKWorkoutSessionState` reflecting real-time state changes.
    var workoutSessionStateStream: AsyncStream<HKWorkoutSessionState> { get }
    
    // MARK: - Workout Snapshot
    
    /// Returns the finalized `HKWorkout` object representing the completed workout session.
    ///
    /// - Returns: An optional `HKWorkout` instance. Returns `nil` if the workout has not ended yet.
    func getWorkout() -> HKWorkout?
    
    /// Returns the latest `WorkoutMetrics` collected during the session.
    ///
    /// Useful for generating summaries or displaying final statistics after the workout ends.
    /// - Returns: A `WorkoutMetrics` instance containing metrics such as duration, distance, and calories.
    func getWorkoutMetrics() -> WorkoutMetrics

    // MARK: - Watch HR Integration

    /// Adds a heart-rate sample received from Watch via WatchConnectivity to the
    /// live workout builder. This ensures Watch HR appears in the saved HKWorkout
    /// even though iPhone owns the workout session (WWDC25 iPhone-primary pattern).
    func addHeartRateSample(_ bpm: Double, at date: Date) async

    /// Resets the internal heart-rate value to 0. Called by the Watch HR watchdog
    /// timer when no reading has been received for an extended period.
    ///
    /// This clears `metrics.heartRate` at the source so that subsequent HealthKit
    /// calorie/energy updates (which yield the full `metrics` struct) no longer
    /// carry a stale HR value back into the TCA state.
    func resetWatchHeartRate()
    
//    // MARK: - Platform Setup
//    
//    #if os(iOS)
//    /// Sets up the handler to receive mirrored sessions from Apple Watch (iOS only)
//    func setupRemoteSessionHandler()
//    #endif
//
}
