//
//  WorkoutSummaryStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/04/2025.
//

import Foundation

/// A protocol that defines the strategy for fetching a workout summary.
///
/// Conforming types are responsible for implementing a strategy to retrieve workout-related
/// data and provide a summary of that data. This abstraction allows different strategies
/// (e.g., fetching all data, filtering by date, type, etc.) to be used interchangeably.
protocol WorkoutSummaryStrategy {
    
    /// Asynchronously fetches a workout summary.
    ///
    /// - Returns: A `Summary` instance containing workout-related data.
    /// - Throws: An error if the fetch operation fails.
    func fetchSummary() async throws -> Summary
}
