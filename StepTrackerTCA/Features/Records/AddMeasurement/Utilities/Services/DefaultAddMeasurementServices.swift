//
//  DefaultAddMeasurementServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/03/2025.
//

import Factory
import Foundation

/// The default implementation of `AddMeasurementServices` for handling measurement persistence.
final class DefaultAddMeasurementServices: AddMeasurementServices {
    
    // MARK: - Dependencies

    @LazyInjected(\.addMeasurementRepository) private var addMeasurementRepository
    
    // MARK: - API
    
    /// Saves a measurement record.
    ///
    /// This function logs the measurement details. In a real implementation, this could be
    /// extended to persist data to a database or an API.
    func saveMeasurement(date: Date, workoutType: WorkoutType, movement: any MovementType, value: String, weightUnit: WeightUnit) async throws {
        try await addMeasurementRepository.saveMeasurement(
            date: date,
            workoutType: workoutType,
            movement: movement,
            value: value,
            weightUnit: weightUnit
        )
    }
}
