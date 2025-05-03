//
//  HKWorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import HealthKit

extension HKWorkoutActivityType {
    /// Returns a user-friendly name for the workout activity
    var name: String {
        switch self {
        case .running:    return "Running"
        case .walking:    return "Walking"
        case .cycling:    return "Cycling"
        case .swimming:   return "Swimming"
        case .yoga:       return "Yoga"
        case .hiking:     return "Hiking"
        case .crossTraining: return "Cross Training"
        default:          return String(describing: self)
        }
    }
}
