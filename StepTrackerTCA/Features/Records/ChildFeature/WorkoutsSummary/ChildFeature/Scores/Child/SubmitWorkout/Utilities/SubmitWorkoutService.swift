//
//  SubmitWorkoutService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 11/04/2025.
//

import Foundation

protocol SubmitWorkoutService {
    
    func submitWorkout(for workoutType: WorkoutType,_ movement: String,
        date: Date,
        value: String,
        unit: String
    ) async throws
    
}
