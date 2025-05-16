//
//  DefaultWorkoutKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/05/2025.
//

import Foundation
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
    
    /// Requests authorization and updates the local authorization state.
    func requestAuthorization() async {
        authorizationState = await workoutScheduler.requestAuthorization()
    }
}
