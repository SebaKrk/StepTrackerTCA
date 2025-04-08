//
//  GoalSummaryFacade.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/04/2025.
//

import Factory

/// A facade that provides simplified access to goal-related functionality.
/// 
/// This class abstracts the underlying implementation details of fetching workout goals
/// by delegating the task to the injected `GoalsRepository`. It serves as a clean interface
/// for higher-level modules to interact with workout goal data.
final class GoalSummaryFacade {

    /// The repository used to fetch workout goals.
    @LazyInjected(\.goalsRepository) private var goalsRepository

    /// Asynchronously fetches all workout goals.
    ///
    /// - Returns: An array of `WorkoutGoal` representing all goals stored in the repository.
    /// - Throws: An error if fetching fails.
    func fetchAllGoals() async throws -> [WorkoutGoal] {
        return try await goalsRepository.fetchAllGoals()
    }
}
