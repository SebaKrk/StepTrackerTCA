//
//  HKWorkoutActivityType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 25/04/2025.
//

import Foundation
import HealthKit
import SwiftUI

extension HKWorkoutActivityType {

    public var color: Color {
        switch self {
        case .crossTraining:                return .orange
        case .running:                      return .green
        case .cycling:                      return .blue
        case .swimming:                     return .cyan
        case .walking:                      return .mint
        case .traditionalStrengthTraining:  return .purple
        case .functionalStrengthTraining:   return .indigo
        case .highIntensityIntervalTraining: return .pink
        case .boxing:                       return .red
        case .cooldown:                     return .gray
        case .hiking:                       return .brown
        case .climbing:                     return .teal
        default:                            return .yellow
        }
    }
    
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
        case .highIntensityIntervalTraining:
            return String(localized: "Endurance", bundle: .module)
        case .cooldown:
            return String(localized: "Cooldown", bundle: .module)
        case .hiking:
            return String(localized: "Hiking", bundle: .module)
        case .climbing:
            return String(localized: "Climbing", bundle: .module)
        default:
            return String(localized: "Other", bundle: .module)
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
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining.circle.fill"
        case .cooldown:        return "figure.cooldown.circle.fill"
        case .hiking:          return "figure.hiking.circle.fill"
        case .climbing:        return "figure.climbing.circle.fill"
        default:               return "figure.mixed.cardio.circle.fill"
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
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .cooldown:         return "figure.cooldown"
        case .hiking:           return "figure.hiking"
        case .climbing:         return "figure.climbing"
        default:                return "figure.mixed.cardio"
        }
    }

    /// Whether HealthKit should auto-collect distance samples for this activity.
    ///
    /// Indoor/stationary workouts produce meaningless "distance" from arm swings
    /// and steps between stations, which then surfaces as the headline metric in
    /// Apple Fitness. Used to gate `HKLiveWorkoutDataSource` collection and to
    /// pick the session's `locationType` on both workout paths (Watch-primary
    /// and iPhone-standalone).
    public var collectsDistance: Bool {
        switch self {
        case .boxing, .traditionalStrengthTraining,
             .functionalStrengthTraining, .crossTraining:
            return false
        default:
            return true
        }
    }

}
