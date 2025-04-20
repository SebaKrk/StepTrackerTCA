//
//  WorkoutStrength.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

struct WorkoutStrength: Identifiable, Equatable, WorkoutSession {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.Strength`.
    let workoutType: String = "Strength"
    
    /// The specific Strength movement performed.
    let movement: String // StrengthMovement
    
    /// The date when the workout was recorded.
    let date: Date
    
    /// The recorded value associated with the workout (e.g., weight lifted or repetitions).
    let value: String
    
    init(id: String, movement: String, date: Date, value: String) {
        self.id = id
        self.movement = movement
        self.date = date
        self.value = value
    }
    
    static func == (lhs: WorkoutStrength, rhs: WorkoutStrength) -> Bool {
        return lhs.id == rhs.id &&
               lhs.workoutType == rhs.workoutType &&
               lhs.value == rhs.value &&
               lhs.date == rhs.date &&
               lhs.movement == rhs.movement
    }
    
}

