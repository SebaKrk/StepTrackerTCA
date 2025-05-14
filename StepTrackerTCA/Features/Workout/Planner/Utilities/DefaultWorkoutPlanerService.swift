//
//  DefaultWorkoutPlanerService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import Foundation
import WorkoutKit

final class DefaultWorkoutPlanerService: WorkoutPlanerService {
    
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout {
//        SingleGoalWorkout(activity: .crossTraining, location: .indoor, goal: .energy(300, .kilocalories))

        SingleGoalWorkout(activity: activity.hkType,
                          location: location.hkType,
                          goal: .energy(300, .kilocalories))
    }
    
}
