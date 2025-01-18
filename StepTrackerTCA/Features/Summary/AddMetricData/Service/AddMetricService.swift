//
//  AddMetricService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/01/2025.
//

import Foundation
import HealthKit

protocol AddMetricService {
    
    /// Adds health data to the HealthKit store for a specific date, value, and type.
    ///
    /// This method saves a single sample of health data, such as step count or body mass,
    /// to the HealthKit store. The data is defined by the specified quantity type, value, and unit.
    ///
    /// - Parameters:
    ///   - date: The date and time associated with the health data.
    ///           This is both the start and end time for the sample.
    ///   - value: The numeric value of the health data (e.g., 5000 for step count or 70.5 for body mass).
    ///   - type: The `HKQuantityTypeIdentifier` representing the type of data to be saved,
    ///           such as `.stepCount` or `.bodyMass`.
    ///   - unit: The `HKUnit` used to represent the value, such as `.count()` for step count
    ///           or `.kilogram()` for body mass.
    ///
    /// - Throws: An error if the HealthKit sample cannot be saved, such as due to lack of
    ///           permissions or invalid parameters.
    func addHealthData(for date: Date, value: Double, type: HKQuantityTypeIdentifier, unit: HKUnit) async throws
}
