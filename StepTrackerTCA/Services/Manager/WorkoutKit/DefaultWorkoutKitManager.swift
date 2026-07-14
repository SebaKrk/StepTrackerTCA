//
//  DefaultWorkoutKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/05/2025.
//

import Foundation
import SharedModels
import WorkoutKit

final class DefaultWorkoutKitManager: WorkoutKitManager {
    
    // MARK: - Properties
    
    private let workoutScheduler: WorkoutScheduler
    private(set) var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    private(set) var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    
    // MARK: - Lifecycle
    
    init(workoutScheduler: WorkoutScheduler = .shared) {
        self.workoutScheduler = workoutScheduler
    }
    
    // MARK: - API
    
    /// Creates a single workout based on the given activity, location, and goal.
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout? {
        guard let goalValue = Double(goal) else { return nil }
        
        return SingleGoalWorkout(activity: activity.hkType,
                                 location: location.hkType,
                                 goal: .energy(goalValue, .kilocalories))
    }
    
    /// Schedules a given workout plan at a specific date asynchronously.
    func schedule(workout: WorkoutPlan, at date: Date) async {
        let components = Calendar.current.dateComponents(in: .current, from: date)
        await workoutScheduler.schedule(workout, at: components)
    }
    
    /// Marks a scheduled workout as complete.
    func markWorkoutComplete(_ workout: ScheduledWorkoutPlan) async {
        let workoutPlan = workout.plan
        let components = workout.date
        await workoutScheduler.markComplete(workoutPlan, at: components)
    }

    /// Removes a specific scheduled workout.
    func removeScheduledWorkout(_ workout: ScheduledWorkoutPlan) async {
        let workoutPlan = workout.plan
        let components = workout.date
        await workoutScheduler.remove(workoutPlan, at: components)
    }
    
    /// Removes all scheduled workouts.
    func removeAllScheduledWorkouts() async {
        await workoutScheduler.removeAllWorkouts()
    }
    
    /// Fetches all scheduled workouts.
    func fetchScheduledWorkouts() async {
        scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
     }
    
    // MARK: - Authorization
    
    /// Requests authorization and updates the local authorization state.
    func requestAuthorization() async {
        authorizationState = await workoutScheduler.requestAuthorization()
    }
    
}
