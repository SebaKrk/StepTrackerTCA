//
//  WeightLiftingRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import Foundation

/// A repository protocol responsible for providing weightlifting-related data.
/// It can be implemented to return either real data (e.g., from a database or network)
/// or mock data (e.g., for testing or previews).
protocol WeightLiftingRepository {

    /// Asynchronously fetches weightlifting data.
    ///
    /// - Returns: An optional array of `WorkoutWeightlifting` objects representing recorded weightlifting stats.
    /// - Throws: An error if fetching fails.
    func fetchWeightLiftingStats() async throws -> [WorkoutWeightlifting]?
    
    /// Asynchronously retrieves dummy weightlifting data for testing or preview purposes.
    ///
    /// - Returns: A tuple containing:
    ///   - `dummyData`: An array of `WeightLiftingMeasurement` objects representing mock measurement data.
    ///   - `goalHistory`: An array of `WeightLiftingGoalHistory` objects representing mock goals.
    ///
    /// This method is useful for populating UI previews or running tests without relying
    /// on real data sources.
    func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory])
 
}
