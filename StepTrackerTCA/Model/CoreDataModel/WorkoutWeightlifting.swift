//
//  WorkoutWeightlifting.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

struct WorkoutWeightlifting: Identifiable, Equatable, WorkoutSessionProtocol {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.weightlifting`.
    let workoutType: WorkoutType = .weightlifting
    
    /// The specific weightlifting movement performed.
    let movement: any MovementType
    
    /// The date when the workout was recorded.
    let date: Date
    
    /// The recorded value associated with the workout (e.g., weight lifted or repetitions).
    let value: String
    
    init(id: String, movement: WeightliftingMovement, date: Date, value: String) {
        self.id = id
        self.movement = movement
        self.date = date
        self.value = value
    }
    
    static func == (lhs: WorkoutWeightlifting, rhs: WorkoutWeightlifting) -> Bool {
        return lhs.id == rhs.id &&
               lhs.workoutType == rhs.workoutType &&
               lhs.value == rhs.value &&
               lhs.date == rhs.date &&
               lhs.movement.title == rhs.movement.title
    }
}
