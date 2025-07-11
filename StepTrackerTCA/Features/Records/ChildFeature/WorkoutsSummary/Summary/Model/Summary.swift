//
//  Summary.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 29/03/2025.
//

import Foundation

/// A structure representing a summary of workout data, including measurements and goals.
///
/// This struct provides an organized way to store and access workout-related data,
/// making it easier to generate reports, display progress, or analyze results.
///
/// Properties:
/// - `measurements`: An array of `WorkoutMeasurement` objects representing individual workout metrics.
/// - `goals`: An array of `WorkoutGoal` objects representing desired objectives or targets.
struct Summary {
    
    /// An array of `WorkoutMeasurement` objects representing individual workout metrics.
    let measurements: [WorkoutMeasurement]
    
    /// An array of `WorkoutGoal` objects representing desired objectives or targets.
    let goals: [WorkoutGoalSum]
    
}
