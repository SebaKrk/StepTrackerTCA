//
//  SingleWorkoutStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/04/2025.
//

import Foundation

/// A strategy for fetching workout summaries filtered by a specific workout type.
///
/// This class implements the `WorkoutSummaryStrategy` protocol to provide a summary that includes
/// only the measurements and goals relevant to the specified workout type.
final class SingleWorkoutStrategy: WorkoutSummaryStrategy {

    // MARK: - Properties
    
    private let facade: WorkoutSummaryFacade
    private let facadeGoal: GoalSummaryFacade
    private let workoutType: WorkoutType

    // MARK: - Lifcycle
    
    init(
        facade: WorkoutSummaryFacade = WorkoutSummaryFacade(),
        facadeGoal: GoalSummaryFacade = GoalSummaryFacade(),
        workoutType: WorkoutType
    ) {
        self.facade = facade
        self.facadeGoal = facadeGoal
        self.workoutType = workoutType
    }

    // MARK: - API
    
    /// Asynchronously fetches and filters measurements and goals based on the workout type.
    func fetchSummary() async throws -> Summary {
        let allMeasurements = try await facade.fetchAllMeasurements()
        let filteredMeasurements = allMeasurements.filter { $0.workoutType == workoutType }
        let goals = try await facadeGoal.fetchAllGoals().filter { $0.workoutType == workoutType.rawValue }
        
        return Summary(measurements: filteredMeasurements, goals: goals)
    }
}
