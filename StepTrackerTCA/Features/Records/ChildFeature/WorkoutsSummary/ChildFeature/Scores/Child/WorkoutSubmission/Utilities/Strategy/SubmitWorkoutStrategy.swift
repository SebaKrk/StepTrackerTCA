//
//  SubmitWorkoutStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import Foundation

/// Strategy for submitting a new workout session.
struct SubmitWorkoutStrategy: WorkoutSubmissionStrategy {
    
    /// Service used to submit workout data.
    let service: SubmitWorkoutService
    
    /// Submits workout data
    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.submitWorkout(for: workout, movement, date: date, value: value, unit: unit)
    }
}
