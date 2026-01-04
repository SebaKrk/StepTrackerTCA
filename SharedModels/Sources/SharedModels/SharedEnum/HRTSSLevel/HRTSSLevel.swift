//
//  HRTSSLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/01/2026.
//

import SwiftUI

/// Heart Rate Training Stress Score (hrTSS) classification.
///
/// hrTSS normalizes training load where 100 = 1 hour at lactate threshold.
/// It is primarily used to estimate recovery needs and guide training planning.
public enum HRTSSLevel: String, CaseIterable, Identifiable, Sendable {
    
    case low = "Low"               // < 150
    case moderate = "Moderate"     // 150–300
    case high = "High"             // 300–450
    case veryHigh = "Very High"    // > 450
    
    public var id: String { rawValue }
    
    // MARK: - Factory
    
    /// Creates a HRTSSLevel from a raw hrTSS value.
    public static func from(value: Double) -> HRTSSLevel {
        switch value {
        case ..<150: return .low
        case 150..<300: return .moderate
        case 300..<450: return .high
        default: return .veryHigh
        }
    }
    
    // MARK: - Display Properties
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
    
    /// Estimated recovery time based on hrTSS.
    public var recoveryEstimate: String {
        switch self {
        case .low: return "1 day recovery"
        case .moderate: return "1–2 days recovery"
        case .high: return "2–4 days recovery"
        case .veryHigh: return "5+ days recovery"
        }
    }
    
    /// Short description for context menu.
    /// Describes recovery demand and impact on subsequent training.
    public var description: String {
        switch self {
        case .low:
            return "Low recovery demand. Next-day training unaffected."
        case .moderate:
            return "Moderate recovery demand. Plan next session carefully."
        case .high:
            return "High recovery demand. Limit hard sessions."
        case .veryHigh:
            return "Very high recovery demand. Extended recovery required."
        }
    }
    
    public var valueRange: Range<Double> {
        switch self {
        case .low: return 0..<150
        case .moderate: return 150..<300
        case .high: return 300..<450
        case .veryHigh: return 450..<Double.infinity
        }
    }
}
