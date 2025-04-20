//
//  WorkoutFitness.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

struct WorkoutFitness: Identifiable, Equatable, WorkoutSession {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.Fitness`.
    let workoutType: String = "Fitness"
    
    /// The specific Strength movement performed.
    let movement: String // FitnessMovement
    
    /// The date when the workout was recorded.
    let date: Date
    
    /// The recorded value associated with the workout
    let value: String
    
    init(id: String, movement: String, date: Date, value: String) {
        self.id = id
        self.movement = movement
        self.date = date
        self.value = value
    }
    
    static func == (lhs: WorkoutFitness, rhs: WorkoutFitness) -> Bool {
        return lhs.id == rhs.id &&
               lhs.workoutType == rhs.workoutType &&
               lhs.value == rhs.value &&
               lhs.date == rhs.date &&
               lhs.movement == rhs.movement
    }
    
}
