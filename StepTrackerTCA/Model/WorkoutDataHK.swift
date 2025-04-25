//
//  WorkoutDataHK.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Foundation
import HealthKit

struct WorkoutDataHK {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let calories: Double
    let activityType: HKWorkoutActivityType
}
