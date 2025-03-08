//
//  WeightLiftingStatsServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

protocol WeightLiftingStatsServices {
    
    /// Asynchronously fetches weightlifting data.
    ///
    /// - Returns: An optional array of `WorkoutWeightlifting`
    func fetchWeightLiftingStats() async throws -> [WorkoutWeightlifting]?
    
    /// Maps the provided goal history and measurements to an array of display models.
    ///
    /// This function first extracts all goals from the given goal histories,
    /// sorts them by creation date (most recent first), and then filters them to
    /// include only the most recent goal per movement. It then finds the latest
    /// measurement for each movement and creates a corresponding display model.
    ///
    /// - Parameters:
    ///   - history: An array of `WeightLiftingGoalHistory` containing the historical goals.
    ///   - measurements: An array of `WeightLiftingMeasurement` representing recorded measurements.
    /// - Returns: An array of `WeightLiftingDisplayModel` to be used for display in the UI.
    func mapData(history: [WeightLiftingGoalHistory], measurements: [WeightLiftingMeasurement]) -> [WeightLiftingDisplayModel]
    
    /// Asynchronously retrieves dummy weightlifting data for testing or preview purposes.
    ///
    /// This method delegates to the repository, which in turn uses the mock data module
    /// to generate a complete set of dummy measurements and goal histories.
    ///
    /// - Returns: A tuple containing:
    ///   - `dummyData`: An array of `WeightLiftingMeasurement` representing mock measurements.
    ///   - `goalHistory`: An array of `WeightLiftingGoalHistory` representing mock goals.
    func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory])
    
}
