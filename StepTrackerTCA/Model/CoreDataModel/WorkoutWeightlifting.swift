//
//  WorkoutWeightlifting.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

struct WorkoutWeightlifting: Identifiable, Equatable {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.weightlifting`.
    let workoutType: WorkoutType = .weightlifting
    
    /// The specific weightlifting movement performed.
    let movement: WeightliftingMovement
    
    /// The date when the workout was recorded.
    let date: Date
    
    /// The recorded value associated with the workout (e.g., weight lifted or repetitions).
    let value: String
    
}
