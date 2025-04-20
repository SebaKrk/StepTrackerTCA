//
//  WorkoutHeroWod.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

struct WorkoutHeroWod: Identifiable, Equatable, WorkoutSession {
    
    /// The unique identifier for the workout session.
    let id: String
    
    /// The type of workout, set to `.Hero`.
    let workoutType: String = "Hero"
    
    /// The specific Strength movement performed.
    let movement: String // HeroMovement
    
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
    
    static func == (lhs: WorkoutHeroWod, rhs: WorkoutHeroWod) -> Bool {
        return lhs.id == rhs.id &&
               lhs.workoutType == rhs.workoutType &&
               lhs.value == rhs.value &&
               lhs.date == rhs.date &&
               lhs.movement == rhs.movement
    }
    
}
