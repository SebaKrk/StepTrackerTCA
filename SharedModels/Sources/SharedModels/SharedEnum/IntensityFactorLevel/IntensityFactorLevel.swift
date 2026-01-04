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
public enum IntensityFactorLevel: String, CaseIterable, Identifiable, Sendable {
    
    case recovery = "Recovery"       // < 0.75
    case aerobic = "Aerobic"         // 0.75–0.85
    case tempo = "Tempo"             // 0.85–0.95
    case threshold = "Threshold"     // 0.95–1.00
    case vo2max = "VO2max"           // 1.00–1.05
    case allOut = "All-out"          // > 1.05
    
    public var id: String { rawValue }
    
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
            return "Very light effort. Active recovery or warm-up intensity."
        case .aerobic:
            return "Comfortable effort. Building aerobic base and endurance."
        case .tempo:
            return "Moderate-hard effort. Improving lactate threshold."
        case .threshold:
            return "Hard effort at lactate threshold. Maximum sustainable pace."
        case .vo2max:
            return "Very hard effort. Training maximum oxygen uptake."
        case .allOut:
            return "Maximum effort. Race pace or sprint intervals."
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
