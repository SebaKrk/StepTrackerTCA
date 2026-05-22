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
    case cycling
    case running

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
        case .cycling:
            return String(localized: "Cycling", bundle: .module)
        case .running:
            return String(localized: "Running", bundle: .module)
        }
    }

    public var iconName: String {
        switch self {
        case .strength:         return "figure.strengthtraining.traditional"
        case .functional:       return "figure.strengthtraining.functional"
        case .cross:            return "figure.cross.training"
        case .boxing:           return "figure.boxing"
        case .cycling:          return "figure.outdoor.cycle"
        case .running:          return "figure.run"
        }
    }

    public var iconCircleFill: String {
        switch self {
        case .strength:   return "figure.strengthtraining.traditional.circle.fill"
        case .functional: return "figure.strengthtraining.functional.circle.fill"
        case .cross:      return "figure.cross.training.circle.fill"
        case .boxing:     return "figure.boxing.circle.fill"
        case .cycling:    return "figure.outdoor.cycle.circle.fill"
        case .running:    return "figure.run.circle.fill"
        }
    }

    /// Map to HealthKit equivalent
    public var hkType: HKWorkoutActivityType {
        switch self {
        case .strength:         return .traditionalStrengthTraining
        case .functional:       return .functionalStrengthTraining
        case .cross:            return .crossTraining
        case .boxing:           return .boxing
        case .cycling:          return .cycling
        case .running:          return .running
        }
    }

    /// Create from HealthKit value
    public init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .traditionalStrengthTraining: self = .strength
        case .functionalStrengthTraining:  self = .functional
        case .crossTraining:               self = .cross
        case .boxing:                      self = .boxing
        case .cycling:                     self = .cycling
        case .running:                     self = .running
        default:                           return nil
        }
    }

    /// Stable string identifier for persistence (e.g. `@Shared(.appStorage)`).
    /// Do **not** rename existing values — they are stored in UserDefaults across app versions.
    public var storageKey: String {
        switch self {
        case .strength:   return "strength"
        case .functional: return "functional"
        case .cross:      return "cross"
        case .boxing:     return "boxing"
        case .cycling:    return "cycling"
        case .running:    return "running"
        }
    }

    /// Reverse mapping from `storageKey`. Returns `nil` for unknown keys (e.g. data
    /// persisted by an older version that referenced a since-removed case).
    public init?(storageKey: String) {
        switch storageKey {
        case "strength":   self = .strength
        case "functional": self = .functional
        case "cross":      self = .cross
        case "boxing":     self = .boxing
        case "cycling":    self = .cycling
        case "running":    self = .running
        default:           return nil
        }
    }

}
