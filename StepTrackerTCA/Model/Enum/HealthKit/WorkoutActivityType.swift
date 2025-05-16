//
//  WorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import HealthKit

enum WorkoutActivityType: CaseIterable, Hashable {
    
    case running
    case walking
    case cycling
    case swimming
    case crossTraining
    case boxing
    
    var title: String {
        switch self {
        case .running:        return "Running"
        case .walking:        return "Walking"
        case .cycling:        return "Cycling"
        case .swimming:       return "Swimming"
        case .crossTraining:  return "Cross Training"
        case .boxing:         return "Boxing"
        }
    }
    
    var iconName: String {
        switch self {
        case .running:        return "figure.run.circle.fill"
        case .walking:        return "figure.walk.circle.fill"
        case .cycling:        return "figure.outdoor.cycle.circle.fill"
        case .swimming:       return "swimmer.circle.fill"
        case .crossTraining:  return "figure.cross.training.circle.fill"
        case .boxing:         return "figure.boxing.circle.fill"
        }
    }
    
    /// Map to HealthKit equivalent
    var hkType: HKWorkoutActivityType {
        switch self {
        case .running:        return .running
        case .walking:        return .walking
        case .cycling:        return .cycling
        case .swimming:       return .swimming
        case .crossTraining:  return .crossTraining
        case .boxing:         return .boxing
        }
    }
    
    /// Create from HealthKit value
    init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .running:        self = .running
        case .walking:        self = .walking
        case .cycling:        self = .cycling
        case .swimming:       self = .swimming
        case .crossTraining:  self = .crossTraining
        case .boxing:         self = .boxing
        default:              return nil
        }
    }
    
}
