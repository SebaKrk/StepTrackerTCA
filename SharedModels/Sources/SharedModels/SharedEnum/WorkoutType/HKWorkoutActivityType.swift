//
//  HKWorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType {
    
    /// Returns a user-friendly name for the workout activity
    public var name: String {
        switch self {
        case .running:
            return String(localized: "Running", bundle: .module)
        case .walking:
            return String(localized: "Walking", bundle: .module)
        case .cycling:
            return String(localized: "Cycling", bundle: .module)
        case .swimming:
            return String(localized: "Swimming", bundle: .module)
        case .crossTraining:
            return String(localized: "Cross Training", bundle: .module)
        case .boxing:
            return String(localized: "Boxing", bundle: .module)
        case .traditionalStrengthTraining:
            return String(localized: "Strength", bundle: .module)
        case .functionalStrengthTraining:
            return String(localized: "Functional", bundle: .module)
        case .cooldown:
            return String(localized: "Cooldown", bundle: .module)
        default:
            return String(describing: self)
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
        case .cooldown:        return "figure.cooldown.circle.fill"
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
        case .cooldown:         return "figure.cooldown"
        default:                return "figure.mixed.cardio"
        }
    }
    
}
