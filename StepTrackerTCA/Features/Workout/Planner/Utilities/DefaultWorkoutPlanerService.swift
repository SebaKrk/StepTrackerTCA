//
//  DefaultWorkoutPlanerService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import Factory
import Foundation
import WorkoutKit

final class DefaultWorkoutPlanerService: WorkoutPlanerService {
    
    // MARK: - Dependency
    
    @Injected(\.workoutKitManager) private var workoutKitManager
    
    // MARK: - API
    
    /// Creates a single workout based on the given activity, location, and goal.
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout? {
      
        workoutKitManager.createSingleWorkout(activity: activity,
                                              location: location,
                                              goal: goal)
    }
    
    /// Schedules a given workout plan at a specific date asynchronously.
    internal func schedule(workout: WorkoutPlan, at date: Date) async {
        await workoutKitManager.schedule(workout: workout, at: date)
    }
    
}
