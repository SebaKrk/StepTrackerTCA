//
//  WeightGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation

/// A protocol defining the service responsible for managing weight goals.
protocol WeightGoalService {
    
    /// Fetches the current weight goal from the storage or service.
     ///
     /// - Returns: An optional `CurrentWeightEntity` representing the user's current weight goal.
     ///            Returns `nil` if no weight goal is set.
     /// - Throws: An error if the fetching process fails.
    func fetchWeightGoal() async throws -> CurrentWeightEntity?
    
}
