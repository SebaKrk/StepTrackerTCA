//
//  WorkoutMeasurement.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/03/2025.
//

import Foundation

/// A structure representing a single workout measurement, capturing data related to a specific exercise or movement.
///
/// This struct provides a way to record and track workout data over time, making it suitable for progress tracking,
/// performance analysis, and workout history management.
///
/// Properties:
/// - `id`: A unique identifier for the measurement.
/// - `workoutType`: The type of workout associated with this measurement (e.g., CrossFit, Strength).
/// - `movement`: The name of the exercise or movement being measured.
/// - `date`: The date when the measurement was taken.
/// - `value`: The recorded value for the measurement, such as weight, time, or repetition count.
struct WorkoutMeasurement: Identifiable {
    
    /// A unique identifier for the measurement.
    let id: String
    
    /// The type of workout associated with this measurement (e.g., CrossFit, Strength).
    let workoutType: WorkoutType
    
    /// The name of the exercise or movement being measured.
    let movement: String
    
    /// The date when the measurement was taken.
    let date: Date
    
    /// The recorded value for the measurement, such as weight, time, or repetition count.
    let value: Double
    
}
