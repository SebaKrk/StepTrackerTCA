//
//  DefaultStrengthScoreService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import Foundation

protocol StrengthScoreService {
    
    func findBestWorkout(from workouts: [WorkoutStrength]) -> WorkoutStrength?
    func groupWorkoutsByMovement(_ data: [WorkoutStrength]) -> [GroupedWorkouts]
}

final class DefaultStrengthScoreService: StrengthScoreService {
    
    func findBestWorkout(from workouts: [WorkoutStrength]) -> WorkoutStrength? {
        return workouts.max(by: { Double($0.value) ?? 0.0 < Double($1.value) ?? 0.0 })
    }
    
    func groupWorkoutsByMovement(_ data: [WorkoutStrength]) -> [GroupedWorkouts] {
        var groupedWorkouts: [GroupedWorkouts] = []
        
        for movement in StrengthMovement.allCases {
            let workoutsForMovement = data.filter { $0.movement == movement }
            if !workoutsForMovement.isEmpty {
                groupedWorkouts.append(GroupedWorkouts(movement: movement, workouts: workoutsForMovement))
            }
        }
        
        return sortGroupedWorkouts(groupedWorkouts)
    }
    
    private func sortGroupedWorkouts(_ groupedWorkouts: [GroupedWorkouts]) -> [GroupedWorkouts] {
        return groupedWorkouts.sorted(by: { $0.movement.rawValue < $1.movement.rawValue })
    }
}

