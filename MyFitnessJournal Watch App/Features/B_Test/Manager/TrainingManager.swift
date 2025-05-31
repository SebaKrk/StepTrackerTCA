//
//  TrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/05/2025.
//

import HealthKit
import HealthKit

/// A protocol that defines an interface for managing a HealthKit-powered workout session.
protocol TrainingManager {
    
    // MARK: - Configuration
    
    /// The currently selected workout activity type (e.g. walking, running).
    var selectedWorkout: HKWorkoutActivityType? { get set }
    
    /// Sets the selected workout type.
    func setSelectedWorkout(_ type: HKWorkoutActivityType?)
    
    /// The current workout builder instance.
    var builder: HKLiveWorkoutBuilder? { get }

    // MARK: - Workout State
    
    /// A boolean indicating whether the workout session is running.
    var workoutSessionIsRunning: Bool { get }
    
    /// A stream that emits the current `workoutSessionIsRunning` state when it changes.
    func workoutSessionIsRunningStream() -> AsyncStream<Bool>
    
    // MARK: - Workout Lifecycle Control
    
    func setValueForSumaryView(_ value: Bool)
//    var showingSummaryView: Bool { get set }

    /// Toggles pause/resume state of the workout session.
    func togglePause()
    
    /// Ends the current workout session.
    func endWorkout()
    
    // MARK: - Workout Metrics
    
    /// A stream that emits updated workout metrics during the session.
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> { get }
}
