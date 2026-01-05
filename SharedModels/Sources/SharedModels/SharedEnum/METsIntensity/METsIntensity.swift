//
//  METsIntensity.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/01/2026.
//

import SwiftUI

/// Metabolic Equivalent of Task (METs) intensity classification.
///
/// METs measure the energy cost of physical activity relative to rest.
/// 1 MET = resting metabolic rate (~3.5 ml O₂/kg/min).
public enum METsIntensity: String, CaseIterable, Identifiable, Sendable {
    
    case light = "Light"           // < 3 METs
    case moderate = "Moderate"     // 3-6 METs
    case vigorous = "Vigorous"     // 6-9 METs
    case veryHigh = "Very High"    // > 9 METs
    
    public var id: String { rawValue }
    
    public var localizedName: String {
        String(localized: String.LocalizationValue(rawValue), bundle: .module)
    }
    
    // MARK: - Factory
    
    /// Creates a METsIntensity from a raw METs value.
    public static func from(value: Double) -> METsIntensity {
        switch value {
        case ..<3: return .light
        case 3..<6: return .moderate
        case 6..<9: return .vigorous
        default: return .veryHigh
        }
    }
    
    // MARK: - Display Properties
    
    public var valueRange: Range<Double> {
        switch self {
        case .light: return 0..<3
        case .moderate: return 3..<6
        case .vigorous: return 6..<9
        case .veryHigh: return 9..<Double.infinity
        }
    }
}
