//
//  WorkoutType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import HealthKit

public enum WorkoutType: CaseIterable, Codable, Hashable, Identifiable, Sendable {
    
    case strength
    case functional
    case cross
    case boxing
    
    public var id: Self { self }
    
    public var title: String {
        switch self {
        case .strength:
            return String(localized: "Strength", bundle: .module)
        case .functional:
            return String(localized: "Functional", bundle: .module)
        case .cross:
            return String(localized: "Cross", bundle: .module)
        case .boxing:
            return String(localized: "Boxing", bundle: .module)
        }
    }
    
    public var iconName: String {
        switch self {
        case .strength:         return "figure.strengthtraining.traditional"
        case .functional:       return "figure.strengthtraining.functional"
        case .cross:            return "figure.cross.training"
        case .boxing:           return "figure.boxing"
        }
    }
    
    public var iconCircleFill: String {
        switch self {
        case .strength:   return "figure.strengthtraining.traditional.circle.fill"
        case .functional: return "figure.strengthtraining.functional.circle.fill"
        case .cross:      return "figure.cross.training.circle.fill"
        case .boxing:     return "figure.boxing.circle.fill"
        }
    }
    
    /// Map to HealthKit equivalent
    public var hkType: HKWorkoutActivityType {
        switch self {
        case .strength:         return .traditionalStrengthTraining
        case .functional:       return .functionalStrengthTraining
        case .cross:            return .crossTraining
        case .boxing:           return .boxing
        }
    }
    
    /// Create from HealthKit value
    public init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .traditionalStrengthTraining: self = .strength
        case .functionalStrengthTraining:  self = .functional
        case .crossTraining:               self = .cross
        case .boxing:                      self = .boxing
        default:                           return nil
        }
    }
    
}
