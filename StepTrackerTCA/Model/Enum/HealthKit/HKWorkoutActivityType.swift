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
        case .running:          return "Running"
        case .walking:          return "Walking"
        case .cycling:          return "Cycling"
        case .swimming:         return "Swimming"
        case .crossTraining:    return "Cross Training"
        case .boxing:           return "Boxing"
        case .traditionalStrengthTraining: return "Strength"
        case .functionalStrengthTraining: return "Functional"
        case .cooldown:         return "Cooldown"
        default:                return String(describing: self)
        }
    }
    
    var iconName: String {
        switch self {
        case .running:          return "figure.run.circle.fill"
        case .walking:          return "figure.walk.circle.fill"
        case .cycling:          return "figure.outdoor.cycle.circle.fill"
        case .swimming:         return "swimmer.circle.fill"
        case .crossTraining:    return "figure.cross.training.circle.fill"
        case .boxing:           return "figure.boxing.circle.fill"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional.circle.fill"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional.circle.fill"
        case .cooldown:         return "figure.cooldown.circle.fill"
        default:                return String(describing: self)
        }
    }
    
}
