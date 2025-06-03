//
//  WorkoutType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import HealthKit

enum WorkoutType: CaseIterable, Codable, Hashable, Identifiable {
    
    case strength
    case functional
    case cross
    case boxing
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .strength:         return "Strength"
        case .functional:       return "Functional"
        case .cross:            return "Cross"
        case .boxing:           return "Boxing"
        }
    }
    
    var iconName: String {
        switch self {
        case .strength:         return "figure.strengthtraining.traditional"
        case .functional:       return "figure.strengthtraining.functional"
        case .cross:            return "figure.cross.training"
        case .boxing:           return "figure.boxing"
        }
    }
    
    /// Map to HealthKit equivalent
    var hkType: HKWorkoutActivityType {
        switch self {
        case .strength:         return .traditionalStrengthTraining
        case .functional:       return .functionalStrengthTraining
        case .cross:            return .crossTraining
        case .boxing:           return .boxing
        }
    }
    
    /// Create from HealthKit value
    init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .traditionalStrengthTraining: self = .strength
        case .functionalStrengthTraining:  self = .functional
        case .crossTraining:               self = .cross
        case .boxing:                      self = .boxing
        default:                           return nil
        }
    }
    
}
