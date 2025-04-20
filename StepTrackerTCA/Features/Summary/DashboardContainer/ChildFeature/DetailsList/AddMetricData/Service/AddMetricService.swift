//
//  AddMetricService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 18/01/2025.
//

import Foundation

protocol AddMetricService {
    
    /// Adds step count data to the HealthKit store for a specific date and value.
     ///
     /// This method simplifies adding step count data by defaulting the type and unit to `.stepCount` and `.count()`.
     ///
     /// - Parameters:
     ///   - date: The date and time associated with the step count.
     ///   - value: The step count value (e.g., 5000 steps).
     ///
     /// - Throws: An error if the step count sample cannot be saved.
     func addSteps(for date: Date, value: Double) async throws
     
     /// Adds body weight data to the HealthKit store for a specific date and value.
     ///
     /// This method simplifies adding weight data by defaulting the type and unit to `.bodyMass` and `.kilogram()`.
     ///
     /// - Parameters:
     ///   - date: The date and time associated with the body weight.
     ///   - value: The weight value in kilograms (e.g., 70.5 for 70.5 kg).
     ///
     /// - Throws: An error if the weight sample cannot be saved.
     func addWeight(for date: Date, value: Double) async throws
}
