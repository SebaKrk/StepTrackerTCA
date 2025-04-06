//
//  DefaultMovementDetailsFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/03/2025.
//

import Foundation

final class DefaultMovementDetailsFeatureServices: MovementDetailsFeatureServices {
    
    /// Generates an array of goal intervals from the provided workout goals.
    func generateGoalIntervals(workoutGoals: [WorkoutGoal], movementName: String) -> [MovementDetailsFeature.GoalInterval] {
        let filteredGoals = workoutGoals.filter { $0.movement == movementName }
        let sortedGoals = filteredGoals.sorted { $0.date < $1.date }
        
        var intervals: [MovementDetailsFeature.GoalInterval] = []
        
        for index in 0..<sortedGoals.count {
            let currentGoal = sortedGoals[index]
            
            let endDate: Date
            if index < sortedGoals.count - 1 {
                endDate = sortedGoals[index + 1].date
            } else {
                endDate = Date()
            }
            
            let interval = MovementDetailsFeature.GoalInterval(start: currentGoal.date, end: endDate, value: currentGoal.value)
            intervals.append(interval)
        }
        
        return intervals
    }
    
    /// Filtruje GroupedMovement, aby zwrócić dane tylko dla konkretnego ćwiczenia (movement).
    func filterGroupedMovementByExercise(_ groupedMovement: GroupedMovement, movementName: String) -> GroupedMovement {
        let filteredMeasurements = groupedMovement.movements.filter { $0.movement == movementName }
        let filteredGoals = groupedMovement.goals?.filter { $0.movement == movementName }
        
        return GroupedMovement(
            workoutType: groupedMovement.workoutType,
            movements: filteredMeasurements,
            goals: filteredGoals
        )
    }
    
}
