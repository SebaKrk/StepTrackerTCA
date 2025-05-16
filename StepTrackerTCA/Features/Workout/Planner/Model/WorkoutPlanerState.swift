//
//  WorkoutPlanerState.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/05/2025.
//

import Foundation

enum WorkoutPlanerState {
    
    /// Initial state of the workout planner.
    case start
    
    /// State where the user is adding or editing a workout.
    case add
    
    /// State for previewing the workout before saving.
    case preview
    
    /// State representing the saving process of the workout.
    case save
    
}
