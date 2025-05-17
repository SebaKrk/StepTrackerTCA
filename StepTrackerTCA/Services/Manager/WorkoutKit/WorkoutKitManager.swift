//
//  WorkoutKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/05/2025.
//

import Foundation
import WorkoutKit

/// A protocol defining the interface for managing workout scheduling and authorization.
///
/// Conforming types are expected to handle the creation, scheduling, and removal of workout plans,
/// as well as manage the authorization state for accessing workout-related functionalities.
protocol WorkoutKitManager {
    
    /// Creates a single workout based on the specified activity, location, and goal.
    ///
    /// - Parameters:
    ///   - activity: The type of workout activity.
    ///   - location: The location where the workout will take place.
    ///   - goal: The fitness goal for the workout, represented as a string.
    /// - Returns: A `SingleGoalWorkout` instance configured with the provided parameters, or `nil` if the goal cannot be converted to a `Double`.
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout?
    
    /// Schedules a given workout plan at a specific date.
    ///
    /// - Parameters:
    ///   - workout: The workout plan to be scheduled.
    ///   - date: The date and time when the workout should occur.
    func schedule(workout: WorkoutPlan, at date: Date) async
    
    /// Marks a scheduled workout as complete.
    ///
    /// - Parameter workout: The scheduled workout plan to be marked as complete.
    func markWorkoutComplete(_ workout: ScheduledWorkoutPlan) async
    
    /// Removes a specific scheduled workout.
    ///
    /// - Parameter workout: The scheduled workout plan to be removed.
    func removeScheduledWorkout(_ workout: ScheduledWorkoutPlan) async
    
    /// Removes all scheduled workouts.
    ///
    /// This function clears all workouts that have been scheduled.
    func removeAllScheduledWorkouts() async
    
    /// Fetches all scheduled workouts.
    ///
    /// Updates the local collection of scheduled workouts with the current list.
    func fetchScheduledWorkouts() async
    
    /// Requests authorization to access workout-related functionalities.
    ///
    /// Updates the local authorization state based on the user's response.
    func requestAuthorization() async
    
}
