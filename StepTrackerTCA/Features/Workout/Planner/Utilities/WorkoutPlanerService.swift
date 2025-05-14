//
//  WorkoutPlanerService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import Foundation
import WorkoutKit

protocol WorkoutPlanerService {
    
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout
}
