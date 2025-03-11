//
//  DefaultStrengthScoreService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import Foundation

final class DefaultStrengthScoreService: StrengthScoreService {
    
    /// Finds the best workout based on the highest value.
    func findBestWorkout(from workouts: [WorkoutStrength]) -> WorkoutStrength {
        return workouts.max(by: { Double($0.value) ?? 0.0 < Double($1.value) ?? 0.0 })!
    }
    
    /// Groups workouts by movement type.
    func groupWorkoutsByMovement(_ data: [WorkoutStrength]) -> [GroupedWorkouts] {
        var groupedWorkouts: [GroupedWorkouts] = []
        
        for movement in StrengthMovement.allCases {
            let workoutsForMovement = data.filter { $0.movement == movement }
            if !workoutsForMovement.isEmpty {
                let bestWorkout: WorkoutStrength = findBestWorkout(from: workoutsForMovement)
                groupedWorkouts.append(GroupedWorkouts(movement: movement, workouts: workoutsForMovement, bestWorkout: bestWorkout))
            }
        }
        
        return sortGroupedWorkouts(groupedWorkouts)
    }
    
    // MARK: - Helpers Methods
    
    /// Sorts grouped workouts by the `rawValue` of the movement.
    ///
    /// - Parameter groupedWorkouts: A list of grouped workouts.
    /// - Returns: A sorted list of `GroupedWorkouts`.
    private func sortGroupedWorkouts(_ groupedWorkouts: [GroupedWorkouts]) -> [GroupedWorkouts] {
        return groupedWorkouts.sorted(by: { $0.movement.rawValue < $1.movement.rawValue })
    }
    
}
