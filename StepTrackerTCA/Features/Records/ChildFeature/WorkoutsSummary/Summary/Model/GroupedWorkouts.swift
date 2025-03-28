//
//  GroupedWorkouts.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/03/2025.
//

import Foundation

/// A structure representing a grouped collection of workouts by type.
///
/// This structure is used to organize multiple `GroupedMovement` instances
/// under a specific `WorkoutType`. It provides a convenient way to categorize
/// workouts based on their type.
///
/// - Conforms to: `Identifiable`
struct GroupedWorkouts: Identifiable {
    
    /// A unique identifier for the grouped workouts.
    ///
    /// The identifier is derived from the associated `WorkoutType` to ensure uniqueness.
    var id: WorkoutType { workoutType }
    
    /// The type of workout associated with this group.
    ///
    /// Determines the category of the workouts in this group.
    let workoutType: WorkoutType
    
    /// A collection of grouped movements related to the workout type.
    ///
    /// Stores all `GroupedMovement` instances belonging to the same `WorkoutType`.
    let movements: [GroupedMovement]
}


///// The goal associated with the workout type.
//let goal: WorkoutGoal?
