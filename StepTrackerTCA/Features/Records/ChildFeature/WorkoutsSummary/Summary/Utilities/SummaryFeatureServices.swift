//
//  SummaryFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A protocol that provides services for retrieving and processing workout summaries.
protocol SummaryFeatureServices {
    
    /// Retrieves a workout summary asynchronously.
    /// - Returns: A `Summary` object containing detailed workout data.
    /// - Throws: An error if the workout summary retrieval fails.
    func fetchWorkoutSummary() async throws -> Summary
    
    /// Groups the given workout summary data into categorized movements.
    /// - Parameter summary: The summary data containing raw workout data to be processed.
    /// - Returns: An array of grouped movements categorized by specific criteria such as activity type or date.
    func groupSummaryData(_ summary: Summary) -> [GroupedMovement]
    
    /// Processes the grouped movements to filter out unique workout measurements for each group.
    /// - Parameter grouped: An array of `GroupedMovement` objects that need to be filtered for unique workout measurements.
    /// - Returns: A new array of `GroupedMovement` objects where the `movements` property contains only unique workout measurements for each group.
    func processGroupedMovements(_ grouped: [GroupedMovement]) -> [GroupedMovement]
    
}
