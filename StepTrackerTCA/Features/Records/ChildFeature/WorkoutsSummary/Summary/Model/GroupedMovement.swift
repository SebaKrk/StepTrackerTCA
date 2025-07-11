//
//  GroupedMovement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/03/2025.
//

import Foundation

/// A structure that represents a collection of workout movements grouped by their type.
///
/// This struct is useful for organizing workout data by workout type,
/// making it easier to categorize and display movements in the user interface.
struct GroupedMovement: Identifiable {
    
    /// A unique identifier for the group, derived from the `workoutType`.
    var id: WorkoutType { workoutType }
    
    /// The type of workout represented by this group (e.g., CrossFit, Strength).
    let workoutType: WorkoutType
    
    /// An array of `WorkoutMeasurement` objects associated with the workout type.
    let movements: [WorkoutMeasurement]
    
    /// An optional array of `WorkoutGoal` objects that define desired outcomes or objectives.
    let goals: [WorkoutGoalSum]?
    
}
