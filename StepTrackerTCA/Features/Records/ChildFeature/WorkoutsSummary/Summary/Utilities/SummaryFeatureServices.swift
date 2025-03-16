//
//  SummaryFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A protocol that provides services for retrieving and processing workout summaries.
protocol SummaryFeatureServices {
    
    /// Fetches the workout summary asynchronously.
    ///
    /// - Returns: A `WorkoutSummary` containing details of past workouts.
    /// - Throws: An error if fetching the summary fails.
    func fetchWorkoutSummary() async throws -> WorkoutSummary
    
    /// Groups workouts by their workout type from the provided summary.
    ///
    /// - Parameter summary: The workout summary containing workout sessions.
    /// - Returns: An array of `GroupedWorkouts`, where workouts are grouped by type.
    func groupWorkoutsByWorkoutType(_ summary: WorkoutSummary) -> [GroupedWorkouts]
    
}
