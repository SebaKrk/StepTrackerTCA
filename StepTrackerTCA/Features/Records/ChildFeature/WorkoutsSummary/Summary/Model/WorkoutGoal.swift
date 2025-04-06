//
//  WorkoutGoal.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/03/2025.
//

import Foundation

/// A structure representing a workout goal, which defines a target or objective for a specific movement.
///
/// This struct provides a way to track progress toward specific workout targets, allowing
/// for detailed analysis and goal-setting within various workout types.
///
/// Properties:
/// - `id`: A unique identifier for the goal.
/// - `workoutType`: The type of workout associated with the goal (e.g., CrossFit, Strength).
/// - `movement`: The specific movement or exercise the goal is related to.
/// - `date`: The date when the goal is set or achieved.
/// - `value`: The target value to achieve, such as a weight, time, or repetition count.
struct WorkoutGoal: Identifiable {
    
    /// A unique identifier for the goal.
    let id: String
    
    /// The type of workout associated with the goal (e.g., CrossFit, Strength).
    let workoutType: String
    
    /// The specific movement or exercise the goal is related to.
    let movement: String
    
    /// The date when the goal is set or achieved.
    let date: Date
    
    /// The target value to achieve, such as a weight, time, or repetition count.
    let value: Double
    
}
