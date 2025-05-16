//
//  WorkoutKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 16/05/2025.
//

import Foundation
import WorkoutKit

protocol WorkoutKitManager {
    
    func createSingleWorkout(activity: WorkoutActivityType,
                             location: WorkoutLocationType,
                             goal: String) -> SingleGoalWorkout?
    
    func schedule(workout: WorkoutPlan, at date: Date) async
    
    func requestAuthorization() async 
}
