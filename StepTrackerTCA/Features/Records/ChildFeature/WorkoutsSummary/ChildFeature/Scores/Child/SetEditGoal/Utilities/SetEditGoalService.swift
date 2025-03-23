//
//  SetEditGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/03/2025.
//

import Foundation

protocol SetEditGoalService {
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) async throws
}
