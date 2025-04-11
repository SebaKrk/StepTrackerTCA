//
//  SubmitWorkoutService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

protocol SubmitWorkoutService {
    
    /// Saves a workout.
    ///
    /// - Parameters:
    ///   - date: The date of the measurement.
    ///   - workoutType: The type of workout (e.g., weightlifting, strength, etc.).
    ///   - movement: The specific movement associated with the measurement.
    ///   - value: The recorded value (e.g., weight, time, reps).
    ///   - weightUnit: The unit of measurement (e.g., kg, lbs).
    func submitWorkout(for workoutType: WorkoutType,_ movement: String,
        date: Date,
        value: String,
        unit: String
    ) async throws
    
}
