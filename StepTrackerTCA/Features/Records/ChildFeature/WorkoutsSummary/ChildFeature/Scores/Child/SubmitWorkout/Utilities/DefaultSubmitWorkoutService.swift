//
//  DefaultSubmitWorkoutService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

final class DefaultSubmitWorkoutService: SubmitWorkoutService {
    
    // MARK: - Dependencies
    
    // MARK: - API
    
    func submitWorkout(for workoutType: WorkoutType, _ movement: String, date: Date, value: String, unit: String) async throws {
        print(workoutType, movement, date, value, unit)
    }
    
}
