//
//  WorkoutPlanerService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import Foundation
import SharedModels
import WorkoutKit

protocol WorkoutPlanerService {
    
    /// Creates a single workout based on the given activity, location, and goal.
    /// - Parameters:
    ///   - activity: The type of workout activity.
    ///   - location: The location type where the workout will take place.
    ///   - goal: The energy goal as a string.
    /// - Returns: An optional `SingleGoalWorkout` instance if creation is successful.
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout?
    
    /// Schedules a given workout plan at a specific date asynchronously.
    /// - Parameters:
    ///   - workout: The workout plan to schedule.
    ///   - date: The date and time to schedule the workout.
    func schedule(workout: WorkoutPlan, at date: Date) async
    
}
