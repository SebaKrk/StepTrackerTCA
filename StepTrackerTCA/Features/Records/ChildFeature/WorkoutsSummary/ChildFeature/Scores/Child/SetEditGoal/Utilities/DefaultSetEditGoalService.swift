//
//  DefaultSetEditGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/03/2025.
//

import Foundation

protocol SetEditGoalService {
    func setNewGoal(for workoutType: WorkoutType, _ movement: (any MovementType)?, date: Date, value: String)
}

final class DefaultSetEditGoalService: SetEditGoalService {
    
    func setNewGoal(for workoutType: WorkoutType,
                    _ movement: (any MovementType)?,
        date: Date,
        value: String
    ) {
        print(workoutType)
        print(movement!)
        print(date)
        print(value)
    }
    
}
