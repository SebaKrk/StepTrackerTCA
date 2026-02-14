//
//  WorkoutPlanerFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import WorkoutKit

/// Implementation of `WorkoutPlanerFeature` state
extension WorkoutPlanerFeature {
    
    @ObservableState
    struct State: Equatable {
        
        // MARK: - Properties
        
        /// Current state of the workout planner (e.g., start, add, preview).
        var planerState: WorkoutPlanerState = .start
        
        /// Selected workout activity type (e.g., running, cross training).
        var workoutActivityType: WorkoutActivityType = .crossTraining
        
        /// Selected workout location type (e.g., indoor, outdoor).
        var workoutLocationType: WorkoutLocationType = .indoor
        
        var warmUp: SimpleWorkoutGoal = .open
        
        
        var coolDOwn: SimpleWorkoutGoal = .timeLimit
        
        /// The currently created or selected workout plan.
        var workoutPlan: WorkoutPlan? = nil
        
        /// The date and time for the workout or data entry.
        /// Defaults to the current date and time.
        var dateAndTime: Date = .now
        
        /// Energy goal value as a string input from the user.
        var energyGoalValue: String = ""
        
        /// Controls whether the workout preview is currently shown.
        var showPreview: Bool = false
        
        /// Indicates if the preview has been seen or closed.
        var seePreview: Bool = false
    }
    
}
