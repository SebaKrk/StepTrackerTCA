//
//  AddMeasurementServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/03/2025.
//

import Foundation

/// A protocol defining measurement-related services.
protocol AddMeasurementServices {
    /// Saves a workout measurement.
    ///
    /// - Parameters:
    ///   - date: The date of the measurement.
    ///   - workoutType: The type of workout (e.g., weightlifting, strength, etc.).
    ///   - movement: The specific movement associated with the measurement.
    ///   - value: The recorded value (e.g., weight, time, reps).
    ///   - weightUnit: The unit of measurement (e.g., kg, lbs).
    func saveMeasurement(date: Date, workoutType: WorkoutType, movement: any MovementType, value: String, weightUnit: WeightUnit) async throws
    
}
