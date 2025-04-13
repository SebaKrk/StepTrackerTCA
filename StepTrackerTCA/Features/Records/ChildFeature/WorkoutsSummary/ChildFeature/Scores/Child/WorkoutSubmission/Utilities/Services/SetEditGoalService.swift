//
//  SetEditGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/03/2025.
//

import Foundation

protocol SetEditGoalService {
    
    /// Sets a new workout goal for a specified workout type and movement.
    ///
    /// This asynchronous function saves or updates the goal in the service's data store.
    ///
    /// - Parameters:
    ///   - workoutType: The type of workout for which the goal is being set (e.g., running, walking).
    ///   - movement: The specific movement or activity related to the goal (e.g., "distance", "steps").
    ///   - date: The date when the goal is being set or updated.
    ///   - value: The value associated with the goal (e.g., "5.0" for distance).
    ///   - unit: The unit of measurement for the goal (e.g., "km", "steps").
    /// - Throws: An error if the goal could not be saved or updated.
    /// - Note: This function is asynchronous and should be awaited.
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) async throws
}
