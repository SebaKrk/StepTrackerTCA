//
//  HKWorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import HealthKit

extension HKWorkoutActivityType {
    
    /// Returns a user-friendly name for the workout activity
    public var name: String {
        switch self {
        case .running:          return "Running"
        case .walking:          return "Walking"
        case .cycling:          return "Cycling"
        case .swimming:         return "Swimming"
        case .crossTraining:    return "Cross Training"
        case .boxing:           return "Boxing"
        case .traditionalStrengthTraining: return "Strength"
        case .functionalStrengthTraining: return "Functional"
        default:                return String(describing: self)
        }
    }
    
    public var iconName: String {
        switch self {
        case .running:          return "figure.run.circle.fill"
        case .walking:          return "figure.walk.circle.fill"
        case .cycling:          return "figure.outdoor.cycle.circle.fill"
        case .swimming:         return "figure.pool.swim.circle.fill"
        case .crossTraining:    return "figure.cross.training.circle.fill"
        case .boxing:           return "figure.boxing.circle.fill"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional.circle.fill"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional.circle.fill"
        default:                return String(describing: self)
        }
    }
    
    public var iconNameSimple: String {
        switch self {
        case .running:          return "figure.run"
        case .walking:          return "figure.walk"
        case .cycling:          return "figure.outdoor.cycle"
        case .swimming:         return "figure.pool.swim"
        case .crossTraining:    return "figure.cross.training"
        case .boxing:           return "figure.boxing"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        default:                return "figure.mixed.cardio"
        }
    }
    
}
