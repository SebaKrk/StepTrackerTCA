//
//  WorkoutStrengthRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

protocol WorkoutStrengthRepository {
    
    /// Asynchronously fetches WorkoutStrength data.
    ///
    /// - Returns: An optional array of `WorkoutStrength
    func fetchWorkoutStrengthSummary() async throws -> [WorkoutStrength]?
    
    func fetchSessions() async throws -> [any WorkoutSessionProtocol] 
}
