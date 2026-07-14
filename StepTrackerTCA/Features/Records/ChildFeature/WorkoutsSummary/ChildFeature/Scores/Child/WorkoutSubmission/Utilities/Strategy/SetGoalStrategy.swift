//
//  SetGoalStrategy.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import Foundation

/// Strategy for setting or editing a workout goal.
struct SetGoalStrategy: WorkoutSubmissionStrategy {
    
    /// Service used to set or edit workout goals.
    let service: SetEditGoalService

    /// Submits goal data
    func submit(workout: WorkoutType, movement: String, date: Date, value: String, unit: String) async throws {
        try await service.setNewGoal(for: workout, movement, date: date, value: value, unit: unit)
    }
}
