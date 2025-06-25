//
//  TrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/05/2025.
//

import HealthKit
import SharedModels

/// A protocol that manages HealthKit-based workout sessions.
///
/// This includes starting a workout, toggling pause/resume, ending the session,
/// and exposing real-time streams for workout metrics and session state.
///
public protocol TrainingManager: Sendable {
    
#if os(watchOS)
    /// The current HKLiveWorkoutBuilder instance used to collect live workout data.
    ///
    /// This is exposed for internal use and should not be modified externally.
    var builder: HKLiveWorkoutBuilder? { get }
#endif
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
    
    /// Pauses or resumes the workout session depending on its current state.
    func togglePause()
    
    /// Ends the current workout session.
    func endWorkout()
    
    // MARK: - Streams
    
    /// A stream that emits live workout metrics, such as heart rate and calories burned.
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> { get }
    
    /// A stream that emits the running state of the workout session.
    ///
    /// Emits `true` if the workout is currently running, otherwise `false`.
    func workoutSessionIsRunningStream() -> AsyncStream<Bool>
    
    
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
    
    // MARK: - Platform Setup
    
    #if os(iOS)
    /// Sets up the handler to receive mirrored sessions from Apple Watch (iOS only)
    func setupRemoteSessionHandler()
    #endif
    
    
    func startWorkout() async 
}
