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
        case .maximumRecovery: return "Maximum Recovery"
        case .optimalReadiness: return "Optimal Readiness"
        case .goodReadiness: return "Good Readiness"
        case .neutralReadiness: return "Neutral Readiness"
        case .moderateFatigue: return "Moderate Fatigue"
        case .highFatigue: return "High Fatigue"
        }
    }
    
    public var description: String {
        switch self {
        case .maximumRecovery: return "No load day - complete restoration"
        case .optimalReadiness: return "Minimal load - peak condition"
        case .goodReadiness: return "Low load - high availability"
        case .neutralReadiness: return "Typical load - standard condition"
        case .moderateFatigue: return "High load - reduced availability"
        case .highFatigue: return "Very high load - priority: recovery"
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
