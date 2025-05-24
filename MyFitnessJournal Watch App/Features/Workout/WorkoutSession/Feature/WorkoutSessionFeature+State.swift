//
//  WorkoutSessionFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit

/// Implementation of `WorkoutSessionFeature` state
extension WorkoutSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var selectedWorkout: HKWorkoutActivityType?
        
        ///
        var workoutSessionIsRunning: Bool = false
        
        /// The currently selected tab in the application.
        ///
        /// Default value is `.workout`.
        var selectedTab: WorkoutSessionScreenAW = .workout
        
        // MARK: - Child State
        
        ///
        var controlsFeature = ControlsFeature.State()
        
        ///
        var workoutMetricFeature = WorkoutMetricFeature.State()
    }
    
}
