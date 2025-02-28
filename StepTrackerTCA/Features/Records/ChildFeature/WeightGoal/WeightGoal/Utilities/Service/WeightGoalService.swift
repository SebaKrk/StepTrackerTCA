//
//  WeightGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation
import Combine

/// A protocol defining a service responsible for retrieving the user's weight goal.
protocol WeightGoalService {
    
    /// Fetches the user's current weight goal from storage or an external service.
    ///
    /// - Returns: An optional `WeightGoal` representing the user's stored weight goal.
    ///            Returns `nil` if no weight goal has been set.
    /// - Throws: An error if the operation fails due to data retrieval issues.
    func fetchWeightGoal() async throws -> WeightGoal?
    
    ///
    func itemsDidChangePublisher() -> AnyPublisher<Void, Never>
}
