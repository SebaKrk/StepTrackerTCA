//
//  WorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import HealthKit

public enum WorkoutActivityType: String, CaseIterable, Hashable, Codable, Sendable {

    case running
    case walking
    case cycling
    case swimming
    case crossTraining
    case functional
    case endurance
    case boxing
    case strengthTraining
    case cooldown

    public var title: String {
        switch self {
        case .running:           return "Running"
        case .walking:           return "Walking"
        case .cycling:           return "Cycling"
        case .swimming:          return "Swimming"
        case .crossTraining:     return "Cross Training"
        case .functional:        return "Functional"
        case .endurance:         return "Endurance"
        case .boxing:            return "Boxing"
        case .strengthTraining:  return "Strength Training"
        case .cooldown:          return "Cooldown"
        }
    }

    public var iconName: String {
        switch self {
        case .running:           return "figure.run.circle.fill"
        case .walking:           return "figure.walk.circle.fill"
        case .cycling:           return "figure.outdoor.cycle.circle.fill"
        case .swimming:          return "swimmer.circle.fill"
        case .crossTraining:     return "figure.cross.training.circle.fill"
        case .functional:        return "figure.strengthtraining.functional.circle.fill"
        case .endurance:         return "figure.highintensity.intervaltraining.circle.fill"
        case .boxing:            return "figure.boxing.circle.fill"
        case .strengthTraining:  return "figure.strengthtraining.traditional.circle.fill"
        case .cooldown:          return "figure.cooldown.circle.fill"
        }
    }

    /// Map to HealthKit equivalent. HealthKit has no native "endurance" type,
    /// so it maps to `.highIntensityIntervalTraining` (closest — lossy on readback).
    public var hkType: HKWorkoutActivityType {
        switch self {
        case .running:           return .running
        case .walking:           return .walking
        case .cycling:           return .cycling
        case .swimming:          return .swimming
        case .crossTraining:     return .crossTraining
        case .functional:        return .functionalStrengthTraining
        case .endurance:         return .highIntensityIntervalTraining
        case .boxing:            return .boxing
        case .strengthTraining:  return .traditionalStrengthTraining
        case .cooldown:          return .cooldown
        }
    }

    /// Create from HealthKit value
    public init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .running:                       self = .running
        case .walking:                       self = .walking
        case .cycling:                       self = .cycling
        case .swimming:                      self = .swimming
        case .crossTraining:                 self = .crossTraining
        case .functionalStrengthTraining:    self = .functional
        case .highIntensityIntervalTraining: self = .endurance
        case .boxing:                        self = .boxing
        case .traditionalStrengthTraining:   self = .strengthTraining
        case .cooldown:                      self = .cooldown
        default:                             return nil
        }
    }

}
