//
//  ScoreStatus.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 26/10/2025.
//

import SwiftUI

/// Represents the qualitative status of a training component score.
///
/// Provides UI-friendly representation of score values with associated
/// colors, icons, and text labels for consistent user feedback.
public enum ScoreStatus: Sendable, Equatable {
    
    case poor
    case belowAverage
    case good
    case excellent
    
    // MARK: - Display Properties
    
    /// Display text for the status
    public var text: String {
        switch self {
        case .poor:
            return String(localized: "Poor", bundle: .module)
        case .belowAverage:
            return String(localized: "Below Average", bundle: .module)
        case .good:
            return String(localized: "Good", bundle: .module)
        case .excellent:
            return String(localized: "Excellent", bundle: .module)
        }
    }
    
    /// SF Symbol icon name for the status
    public var icon: String {
        switch self {
        case .poor: return "xmark.circle.fill"
        case .belowAverage: return "exclamationmark.triangle.fill"
        case .good: return "minus.circle.fill"
        case .excellent: return "checkmark.circle.fill"
        }
    }
    
    /// Color associated with the status
    public var color: Color {
        switch self {
        case .poor: return .red
        case .belowAverage: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
    
}
