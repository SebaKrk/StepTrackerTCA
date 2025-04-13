//
//  DefaultSubmitWorkoutService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Factory
import Foundation

final class DefaultSubmitWorkoutService: SubmitWorkoutService {
    
    // MARK: - Dependencies

    @LazyInjected(\.addMeasurementRepository) private var addMeasurementRepository
    
    // MARK: - API
    
    /// Saves a measurement record.
    func submitWorkout(for workoutType: WorkoutType, _ movement: String,
                       date: Date,
                       value: String,
                       unit: String) async throws {
        try await addMeasurementRepository.saveMeasurement(
            date: date,
            workoutType: workoutType,
            movement: movement,
            value: value,
            unit: unit
        )
    }
    
}
