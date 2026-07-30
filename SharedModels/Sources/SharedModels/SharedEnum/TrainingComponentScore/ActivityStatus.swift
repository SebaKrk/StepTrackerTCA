//
//  ActivityStatus.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 26/10/2025.
//

import SwiftUI

/// Represents the activity load status based on previous day's training load
/// relative to baseline (7-day average).
///
/// Used to provide contextual feedback about recovery status and training readiness
/// based on the percentage of baseline load from the previous day.
public enum ActivityStatus: Sendable, Equatable {
    
    case maximumRecovery      // 0-15%
    case optimalReadiness     // 15-45%
    case goodReadiness        // 45-80%
    case neutralReadiness     // 80-130%
    case moderateFatigue      // 130-180%
    case highFatigue          // 180%+
    
    // MARK: - Display Properties
    
    public var title: String {
        switch self {
        case .maximumRecovery:
            return String(localized: "Maximum Recovery", bundle: .module)
        case .optimalReadiness:
            return String(localized: "Optimal Readiness", bundle: .module)
        case .goodReadiness:
            return String(localized: "Good Readiness", bundle: .module)
        case .neutralReadiness:
            return String(localized: "Neutral Readiness", bundle: .module)
        case .moderateFatigue:
            return String(localized: "Moderate Fatigue", bundle: .module)
        case .highFatigue:
            return String(localized: "High Fatigue", bundle: .module)
        }
    }
    
    public var description: String {
        switch self {
        case .maximumRecovery:
            return String(localized: "No load day - complete restoration", bundle: .module)
        case .optimalReadiness:
            return String(localized: "Minimal load - peak condition", bundle: .module)
        case .goodReadiness:
            return String(localized: "Low load - high availability", bundle: .module)
        case .neutralReadiness:
            return String(localized: "Typical load - standard condition", bundle: .module)
        case .moderateFatigue:
            return String(localized: "High load - reduced availability", bundle: .module)
        case .highFatigue:
            return String(localized: "Very high load - priority: recovery", bundle: .module)
        }
    }
    
    public var icon: String {
        switch self {
        case .maximumRecovery: return "sparkles"
        case .optimalReadiness: return "bolt.fill"
        case .goodReadiness: return "checkmark.circle.fill"
        case .neutralReadiness: return "minus.circle.fill"
        case .moderateFatigue: return "exclamationmark.triangle.fill"
        case .highFatigue: return "battery.0percent"
        }
    }
    
    /// Color associated with the status for UI presentation
    public var color: Color {
        switch self {
        case .maximumRecovery: return .green
        case .optimalReadiness: return .green
        case .goodReadiness: return .yellow
        case .neutralReadiness: return .yellow
        case .moderateFatigue: return .orange
        case .highFatigue: return .red            
        }
    }
    
    // MARK: - Factory Method
    
    /// Creates activity status from load percentage relative to baseline.
    ///
    /// - Parameter loadPercentage: Yesterday's load as percentage of 7-day baseline (0-∞)
    /// - Returns: Appropriate activity status for the given load percentage
    ///
    /// ## Example
    /// ```swift
    /// let status = ActivityStatus.from(loadPercentage: 50.0)  // .goodReadiness
    /// ```
    public static func from(loadPercentage: Double) -> ActivityStatus {
        switch loadPercentage {
        case 0..<15: return .maximumRecovery
        case 15..<45: return .optimalReadiness
        case 45..<80: return .goodReadiness
        case 80..<130: return .neutralReadiness
        case 130..<180: return .moderateFatigue
        default: return .highFatigue
        }
    }
    
}
