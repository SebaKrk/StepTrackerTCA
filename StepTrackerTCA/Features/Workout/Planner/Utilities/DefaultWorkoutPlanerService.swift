//
//  DefaultWorkoutPlanerService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import Foundation
import WorkoutKit

final class DefaultWorkoutPlanerService: WorkoutPlanerService {
    
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
    internal func schedule(workout: WorkoutPlan, at date: Date) async {
        let components = Calendar.current.dateComponents(in: .current, from: date)
        await WorkoutScheduler.shared.schedule(workout, at: components)
    }
    
}
