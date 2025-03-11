//
//  StrengthScoreService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/03/2025.
//

import Foundation

/// Protocol defining services related to strength assessment based on workouts.
protocol StrengthScoreService {
    
    /// Finds the best workout based on the highest value.
    ///
    /// - Parameter workouts: A list of strength workouts.
    /// - Returns: The best workout based on the highest value.
    func findBestWorkout(from workouts: [WorkoutStrength]) -> WorkoutStrength

    /// Groups workouts by movement type.
    ///
    /// - Parameter data: A list of strength workouts to be grouped.
    /// - Returns: A list of grouped workouts, each containing the best workout for that group.
    func groupWorkoutsByMovement(_ data: [WorkoutStrength]) -> [GroupedWorkouts]
}
