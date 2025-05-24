//
//  DefaultWorkoutSessionService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Factory
import Foundation
import HealthKit

final class DefaultWorkoutSessionService: WorkoutSessionService {
    
    // MARK: - Dependency
    
    @Injected(\.workoutManager) private var workoutManager
    
    // MARK: - API
    
    func updateWorkoutActivityType(_ workoutType: HKWorkoutActivityType) {
        workoutManager.selectedWorkout = workoutType
    }
    
    
}
