//
//  GoalsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/03/2025.
//

import Foundation

/// A repository protocol for managing workout-related goals.
///
/// - Provides an interface for setting new fitness goals associated with different workout types.
protocol GoalsRepository {
    
    ///
    /// Sets a new goal for a specific workout type.
    ///
    /// - Parameters:
    ///   - workoutType: The type of workout the goal is associated with.
    ///   - movement: A specific movement or exercise within the workout.
    ///   - date: The date when the goal is set.
    ///   - value: The target value for the goal.
    ///   - unit: The unit of measurement for the goal (e.g., kg, reps, minutes).
    /// - Throws: An error if the goal cannot be saved.
    /// - Note: This method is asynchronous and must be awaited.
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) async throws
    
    ///
    func fetchAllGoals() async throws -> [WorkoutGoalSum]
    
}
