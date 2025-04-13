//
//  WorkoutSubmissionStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

/// A strategy interface for submitting different types of workout-related data.
protocol WorkoutSubmissionStrategy {
    
    /// Submits workout data based on specific strategy requirements.
    ///
    /// - Parameters:
    ///   - workout: The type of workout being submitted.
    ///   - movement: The movement associated with the workout.
    ///   - date: The date of the workout or goal.
    ///   - value: The primary value (e.g., reps, distance).
    ///   - unit: The unit for the value (e.g., kg, km).
    func submit(
        workout: WorkoutType,
        movement: String,
        date: Date,
        value: String,
        unit: String
    ) async throws
    
}
