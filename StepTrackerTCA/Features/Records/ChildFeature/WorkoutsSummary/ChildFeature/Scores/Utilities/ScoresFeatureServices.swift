//
//  ScoresFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A protocol defining services related to evaluating workout sessions.
protocol ScoresFeatureServices {
    
    /// Returns the best workout session from the given list of sessions.
    ///
    /// This function identifies the workout session with the highest recorded value.
    /// - Parameter sessions: An array of workout sessions conforming to `WorkoutSessionProtocol`.
    /// - Returns: The best workout session or `nil` if no sessions are available.
    func bestSession(from sessions: [any WorkoutSession]) -> (any WorkoutSession)?
    
    /// Fetches the workout summary for a specified workout type.
    ///
    /// This function retrieves workout measurements and associated goals for the given workout type.
    /// - Parameter workoutType: The type of workout to retrieve a summary for.
    /// - Returns: A `Summary` object containing the fetched workout measurements and goals.
    /// - Throws: An error if the fetch operation fails.
    func fetchSummary(for workoutType: WorkoutType) async throws -> Summary
    
    /// Maps the provided summary data into a grouped movement structure.
    ///
    /// - Parameters:
    ///   - summary: The summary data to be mapped into grouped movements.
    ///   - workoutType: The type of workout related to the grouped movements.
    /// - Returns: A `GroupedMovement` object representing the mapped workout data.
    func mapToGroupedMovement(from summary: Summary, workoutType: WorkoutType) -> GroupedMovement

    /// Filters movements from the provided summary based on predefined criteria.
    ///
    /// This function groups measurements by movement name and associates each movement
    /// with its best measurement, most recent measurement, and any relevant goals.
    /// - Parameter summary: The summary data containing all movements.
    /// - Returns: An array of `ScoresFeature.FilteredMovement` objects filtered from the summary.
    func filterMovements(from summary: Summary) -> [ScoresFeature.FilteredMovement]
}
