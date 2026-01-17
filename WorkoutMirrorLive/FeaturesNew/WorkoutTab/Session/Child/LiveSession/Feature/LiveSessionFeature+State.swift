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
        
        /// Live Activity management (delegated to child reducer)
        var liveActivity = LiveActivityFeature.State()
        
        // MARK: - Stopwatch
        
        /// Whether stopwatch view is visible
        var isStopwatchVisible: Bool = false
        
        /// Stopwatch elapsed time in seconds
        var stopwatchTime: TimeInterval = 0
        
        /// Whether stopwatch is currently running
        var isStopwatchRunning: Bool = false
    }
    
}
