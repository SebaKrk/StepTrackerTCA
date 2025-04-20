//
//  AllWorkoutStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/04/2025.
//

import Foundation

final class AllWorkoutStrategy: WorkoutSummaryStrategy {

    private let measurementFacade = WorkoutSummaryFacade()
    private let goalFacade = GoalSummaryFacade()

    /// Asynchronously fetches all workout measurements and goals, then combines them into a `Summary`.
    ///
    /// This method concurrently fetches data using the `WorkoutSummaryFacade` and `GoalSummaryFacade`.
    /// It leverages Swift's `async let` to perform the fetches in parallel for efficiency.
    ///
    /// - Returns: A `Summary` instance containing all fetched measurements and goals.
    /// - Throws: An error if either fetch operation fails.
    func fetchSummary() async throws -> Summary {
        async let measurements = measurementFacade.fetchAllMeasurements()
        async let goals = goalFacade.fetchAllGoals()
        
        return try await Summary(measurements: measurements, goals: goals)
    }
}
