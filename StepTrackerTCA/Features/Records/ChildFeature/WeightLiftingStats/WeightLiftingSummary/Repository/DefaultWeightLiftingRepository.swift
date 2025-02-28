//
//  DefaultWeightLiftingRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import Foundation

/// The default implementation of the `WeightLiftingRepository` protocol,
final class DefaultWeightLiftingRepository: WeightLiftingRepository {
    
    // MARK: - Dependencies
    
    // MARK: - Properties
    
    // MARK: - API
    
    // MARK: - Mock Data
    /// Asynchronously retrieves dummy weightlifting data for testing or previews.
    ///
    /// - Returns: A tuple containing:
    ///   - `dummyData`: An array of `WeightLiftingMeasurement` objects representing mock measurement data.
    ///   - `goalHistory`: An array of `WeightLiftingGoalHistory` objects representing mock goals.
    ///
    /// This method allows the feature to be tested or previewed without relying on real data sources.
    func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory]) {
        await MockWeightLiftingData.getDummyData()
    }
    
}
