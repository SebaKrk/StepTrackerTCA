//
//  MovementDetailsFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 30/03/2025.
//

import Foundation

/// A protocol defining services related to processing workout data for the `MovementDetailsFeature`.
protocol MovementDetailsFeatureServices {
    
    /// Generates an array of goal intervals from the provided workout goals for a specific movement.
    ///
    /// This function is responsible for creating time intervals between consecutive workout goals
    /// related to a particular exercise (movement). It returns an array of `GoalInterval` structures,
    /// each representing a time range between goals with a specified value.
    ///
    /// - Parameters:
    ///   - workoutGoals: An array of `WorkoutGoal` objects to be processed.
    ///   - movementName: The name of the movement (e.g., "Snatch", "Squat") for which intervals are generated.
    /// - Returns: An array of `GoalInterval` objects, or an empty array if insufficient goals are provided.
    func generateGoalIntervals(workoutGoals: [WorkoutGoal], movementName: String) -> [MovementDetailsFeature.GoalInterval]
    
    /// Filters a `GroupedMovement` to return only data related to a specific exercise.
    ///
    /// This function processes a given `GroupedMovement` and filters its contents to include only
    /// the data relevant to the specified movement name. It creates a new `GroupedMovement` containing
    /// only the filtered measurements and goals associated with that exercise.
    ///
    /// - Parameters:
    ///   - groupedMovement: The complete set of data (`GroupedMovement`) to be filtered.
    ///   - movementName: The name of the movement to filter by (e.g., "Snatch", "Squat").
    /// - Returns: A new `GroupedMovement` containing only the filtered data related to the specified movement.
    func filterGroupedMovementByExercise(_ groupedMovement: GroupedMovement, movementName: String) -> GroupedMovement
    
    func selectedWorkoutMeasurement(from measurements: [WorkoutMeasurement], with rawSelectedDate: Date?) -> WorkoutMeasurement?
}
