//
//  IntensityFactorLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import SwiftUI

/// Intensity Factor (IF) classification based on workout effort.
///
/// IF indicates how hard you worked relative to your lactate threshold.
/// Formula: IF = avgHR / LTHR where LTHR = maxHR × 0.85
public enum IntensityFactorLevel: CaseIterable, Identifiable, Sendable {
    
    case recovery       // < 0.75
    case aerobic        // 0.75–0.85
    case tempo          // 0.85–0.95
    case threshold      // 0.95–1.00
    case vo2max         // 1.00–1.05
    case allOut         // > 1.05

    public var id: String { title }
    
    /// Title key for localization
    public var title: String {
        switch self {
        case .recovery: return String(localized: "Recovery", bundle: .module)
        case .aerobic: return String(localized: "Aerobic", bundle: .module)
        case .tempo: return String(localized: "Tempo", bundle: .module)
        case .threshold: return String(localized: "Threshold", bundle: .module)
        case .vo2max: return String(localized: "VO2max", bundle: .module)
        case .allOut: return String(localized: "All-out", bundle: .module)
        }
    }

    // MARK: - Factory
    
    /// Creates an IntensityFactorLevel from a raw IF value.
    public static func from(value: Double) -> IntensityFactorLevel {
        switch value {
        case ..<0.75: return .recovery
        case 0.75..<0.85: return .aerobic
        case 0.85..<0.95: return .tempo
        case 0.95..<1.00: return .threshold
        case 1.00..<1.05: return .vo2max
        default: return .allOut
        }
    }
    
    // MARK: - Display Properties
    
    public var color: Color {
        switch self {
        case .recovery: return .blue
        case .aerobic: return .green
        case .tempo: return .yellow
        case .threshold: return .orange
        case .vo2max: return .red
        case .allOut: return .purple
        }
    }
    
    /// Short description for context menu.
    public var description: String {
        switch self {
        case .recovery:
            return String(localized: "Very light effort. Active recovery or warm-up intensity.", bundle: .module)
        case .aerobic:
            return String(localized: "Comfortable effort. Building aerobic base and endurance.", bundle: .module)
        case .tempo:
            return String(localized: "Moderate-hard effort. Improving lactate threshold.", bundle: .module)
        case .threshold:
            return String(localized: "Hard effort at lactate threshold. Maximum sustainable pace.", bundle: .module)
        case .vo2max:
            return String(localized: "Very hard effort. Training maximum oxygen uptake.", bundle: .module)
        case .allOut:
            return String(localized: "Maximum effort. Race pace or sprint intervals.", bundle: .module)
        }
    }
    
    public var valueRange: Range<Double> {
        switch self {
        case .recovery: return 0..<0.75
        case .aerobic: return 0.75..<0.85
        case .tempo: return 0.85..<0.95
        case .threshold: return 0.95..<1.00
        case .vo2max: return 1.00..<1.05
        case .allOut: return 1.05..<Double.infinity
        }
    }
}
