//
//  GroupedWorkouts.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import Foundation

/// A structure representing a grouped collection of strength workouts.
struct GroupedWorkouts: Identifiable {
    
    /// The unique identifier for the group, based on the movement type.
    var id: StrengthMovement { movement }
    
    /// The type of strength movement associated with the workouts.
    let movement: StrengthMovement
    
    /// The list of strength workouts associated with the movement.
    let workouts: [WorkoutStrength]
    
    /// The best workout among the grouped workouts.
    let bestWorkout: WorkoutStrength
    
}
