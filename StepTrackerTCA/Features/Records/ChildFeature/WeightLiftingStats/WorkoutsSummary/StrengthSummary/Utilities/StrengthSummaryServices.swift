//
//  StrengthSummaryServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import Foundation

/// A protocol defining services for fetching and processing strength-based workout summaries.
protocol StrengthSummaryServices {
    
    /// Asynchronously fetches workout strength data.
    ///
    /// - Returns: An optional array of `WorkoutStrength` representing strength-based workout summaries.
    /// - Throws: An error if fetching data fails.
    func fetchWorkoutStrengthSummary() async throws -> [WorkoutStrength]?
    
    /// Maps fetched `WorkoutStrength` data into `MovementSummary` objects.
    ///
    /// - Parameters:
    ///   - goal: An optional goal value for the movement summary.
    ///   - data: An array of `WorkoutStrength` representing workout data.
    /// - Returns: An array of `MovementSummary` objects of a generic movement type `T`.
    func mapToMovementSummaries<T: MovementType>(_ goal: Double?, data: [WorkoutStrength]) -> [MovementSummary<T>]
}
