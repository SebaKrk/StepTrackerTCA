//
//  TRIMPLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/01/2026.
//

import SwiftUI

/// Training Impulse (TRIMP) classification based on training load.
///
/// TRIMP quantifies training load by combining duration and intensity
/// (heart rate zones). Higher values indicate greater systemic
/// physiological stress and longer stress impact duration.
public enum TRIMPLevel: String, CaseIterable, Identifiable, Sendable {

    case veryLight = "Very Light"        // < 50
    case light = "Light"                 // 50–100
    case moderate = "Moderate"           // 100–150
    case moderateHigh = "Moderate–High"  // 150–200
    case high = "High"                   // 200–300
    case veryHigh = "Very High"          // 300–400
    case extreme = "Extreme"             // > 400

    public var id: String { rawValue }

    // MARK: - Factory

    /// Creates a TRIMPLevel from a raw TRIMP value.
    public static func from(value: Double) -> TRIMPLevel {
        switch value {
        case ..<50: return .veryLight
        case 50..<100: return .light
        case 100..<150: return .moderate
        case 150..<200: return .moderateHigh
        case 200..<300: return .high
        case 300..<400: return .veryHigh
        default: return .extreme
        }
    }

    // MARK: - Display Properties

    public var color: Color {
        switch self {
        case .veryLight: return .mint
        case .light: return .green
        case .moderate: return .yellow
        case .moderateHigh: return .orange
        case .high: return .red
        case .veryHigh: return .purple
        case .extreme: return .pink
        }
    }

    /// Estimated duration of systemic stress impact.
    /// This does NOT represent training recovery planning.
    public var stressImpactEstimate: String {
        switch self {
        case .veryLight: return "< 12 hours"
        case .light: return "12–24 hours"
        case .moderate: return "~1 day"
        case .moderateHigh: return "1–2 days"
        case .high: return "2–3 days"
        case .veryHigh: return "3–4 days"
        case .extreme: return "4+ days"
        }
    }

    /// Short description for context menu (1–2 lines).
    /// Describes systemic training stress and its impact duration.
    public var description: String {
        switch self {
        case .veryLight:
            return "Negligible training stress with no meaningful systemic impact."
        case .light:
            return "Low training stress with minimal systemic impact."
        case .moderate:
            return "Moderate training stress causing short-term systemic impact."
        case .moderateHigh:
            return "Elevated training stress with noticeable systemic impact."
        case .high:
            return "High training stress with extended systemic impact."
        case .veryHigh:
            return "Very high training stress with multi-day systemic impact."
        case .extreme:
            return "Extreme training stress causing prolonged systemic impact."
        }
    }

    /// Full description for detail or info views.
    public var detailedDescription: String {
        switch self {
        case .veryLight:
            return "Very low systemic training stress. Typical for rest days, short walks, or mobility work. Does not meaningfully affect overall physiological load."

        case .light:
            return "Low systemic training stress. Common for easy endurance or recovery sessions. Supports circulation without accumulating fatigue."

        case .moderate:
            return "Moderate training stress providing a noticeable physiological stimulus. Typical for steady endurance or tempo efforts."

        case .moderateHigh:
            return "Elevated training stress caused by longer duration or sustained time in higher heart rate zones. May lead to residual fatigue."

        case .high:
            return "High systemic training stress resulting from prolonged or high-intensity efforts. Represents a substantial physiological load."

        case .veryHigh:
            return "Very high training stress approaching competition-level load. Significant systemic fatigue is expected."

        case .extreme:
            return "Exceptional training stress typical of races or ultra-endurance efforts. Causes deep systemic fatigue and requires extended stress dissipation."
        }
    }

    public var valueRange: ClosedRange<Double> {
        switch self {
        case .veryLight: return 0...50
        case .light: return 50...100
        case .moderate: return 100...150
        case .moderateHigh: return 150...200
        case .high: return 200...300
        case .veryHigh: return 300...400
        case .extreme: return 400...1000
        }
    }
}
