//
//  WorkoutSessionService 2.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Factory
import Foundation
import HealthKit

protocol WorkoutSessionService {
    func updateWorkoutActivityType(_ workoutType: HKWorkoutActivityType)
}
