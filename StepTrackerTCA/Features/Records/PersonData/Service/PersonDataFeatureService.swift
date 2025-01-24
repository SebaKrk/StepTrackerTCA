//
//  PersonDataFeatureService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import Foundation

protocol PersonDataFeatureService {
    
    /// Fetches body mass data asynchronously.
    ///
    /// Shown in the step chart on the dashboard after successful retrieval of data.
    ///
    /// - Returns: An array of `HealthData` objects representing step metrics.
    /// - Throws: An error if data retrieval fails.
    func getWeightData() async throws -> [HealthData]
    
}
