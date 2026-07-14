//
//  AddMeasurementRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/03/2025.
//

import Foundation

/// A repository protocol responsible for handling measurement data persistence.
protocol AddMeasurementRepository {
    
    /// Saves a workout measurement.
    ///
    /// This method stores a measurement associated with a specific workout.
    ///
    /// - Parameters:
    ///   - date: The date of the measurement.
    ///   - workoutType: The type of workout (e.g., weightlifting, strength, etc.).
    ///   - movement: The specific movement associated with the measurement.
    ///   - value: The recorded value (e.g., weight, time, reps).
    ///   - unit: The unit of measurement (e.g., kg, lbs, sec, reps).
    /// - Throws: An error if saving fails.
    func saveMeasurement(
        date: Date,
        workoutType: WorkoutType,
        movement: String,
        value: String,
        unit: String
    ) async throws
    
}
