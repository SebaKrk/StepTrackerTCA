//
//  DefaultSetEditGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 20/03/2025.
//

import Factory
import Foundation

final class DefaultSetEditGoalService: SetEditGoalService {
    
    // MARK: - Dependencies

    @LazyInjected(\.goalsRepository) private var goalsRepository
    
    // MARK: - API
    
    /// Sets a new workout goal for a specified workout type and movement.
    func setNewGoal(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) async throws {
        print("goalsRepository.setNewGoal")
//        try await goalsRepository.setNewGoal(for: workoutType, movement, date: date, value: value, unit: unit)
    }
    
}
