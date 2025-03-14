//
//  WorkoutStrength.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

struct WorkoutStrength: Identifiable, Equatable {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.Strength`.
    let workoutType: WorkoutType = .strength
    
    /// The specific Strength movement performed.
    let movement: StrengthMovement // MovementType
    
    /// The date when the workout was recorded.
    let date: Date
    
    /// The recorded value associated with the workout (e.g., weight lifted or repetitions).
    let value: String
    
}
