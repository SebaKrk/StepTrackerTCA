//
//  LiveSessionFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `LiveSessionFeature` state
extension LiveSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The current metrics of the workout, such as heart rate and active energy burned.
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
        /// The currently calculated heart rate zone for the user, based on HR max and current HR.
        var currentHeartRateZone: HeartRateZone = .resting

        /// The user's current heart rate as a percentage of the maximum heart rate.
        var currentHeartRatePercentage: Int = 0

        /// The average heart rate calculated across the current session.
        var sessionAverageHeartRate: Int = 0

        /// The maximum heart rate recorded so far in the current session.
        var sessionMaxHeartRate: Int = 0

        /// The maximum heart rate (HR max) calculated at the beginning of the session.
        /// Provided by `SessionFeature`, which retrieves the user’s age and biological sex
        /// from `personCalculatorClient` and applies the appropriate calculation strategy.
        var maxHeartRate: Int = 0
        
        // MARK: - Child
        
        /// Live Activity management (delegated to child reducer)
        var liveActivity = LiveActivityFeature.State()
        
        /// Stopwatch state managed by child reducer
        var stopwatch = StopwatchFeature.State()
        
        // MARK: - Helpers
        
        /// Creates Timer Activity Content State from current state
        var timerContentState: TimerActivityAttributes.ContentState {
            TimerActivityAttributes.ContentState(
                heartRate: workoutMetrics.heartRate,
                heartRateZone: currentHeartRateZone,
                elapsedTime: stopwatch.time,
                isRunning: stopwatch.isRunning
            )
        }
        
        /// Creates Workout Activity Content State from current state
        var workoutContentState: WorkoutSessionActivityAttributes.ContentState {
            WorkoutSessionActivityAttributes.ContentState(
                heartRate: workoutMetrics.heartRate,
                heartRateZone: currentHeartRateZone,
                heartRatePercentage: currentHeartRatePercentage,
                activeEnergy: workoutMetrics.activeEnergy,
                maxHeartRate: sessionMaxHeartRate,
                averageHeartRate: sessionAverageHeartRate
            )
        }
    }
    
}
