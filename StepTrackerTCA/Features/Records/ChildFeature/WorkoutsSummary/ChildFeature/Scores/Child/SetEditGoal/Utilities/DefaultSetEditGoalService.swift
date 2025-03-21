//
//  DefaultSetEditGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/03/2025.
//

import Foundation

protocol SetEditGoalService {
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String)
}

final class DefaultSetEditGoalService: SetEditGoalService {
    
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) {
        print(workoutType)
        print(movement)
        print(date)
        print(value)
        print(unit)
    }
    
}
