//
//  HRRecoveryLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/01/2026.
//

import SwiftUI

/// Heart Rate Recovery classification based on BPM drop after exercise.
///
/// HR Recovery measures how quickly heart rate drops in the first minute
/// after stopping exercise. Faster recovery reflects a more responsive
/// autonomic nervous system and better short-term recovery state.
public enum HRRecoveryLevel: String, CaseIterable, Identifiable, Sendable {
    
    case poor = "Poor"             // < 12 bpm
    case average = "Average"       // 12–20 bpm
    case good = "Good"             // 20–30 bpm
    case veryGood = "Very Good"    // 30–40 bpm
    case excellent = "Excellent"   // > 40 bpm
    
    public var id: String { rawValue }
    
    // MARK: - Factory
    
    /// Creates a HRRecoveryLevel from a raw BPM drop value.
    public static func from(value: Int) -> HRRecoveryLevel {
        switch value {
        case ..<12: return .poor
        case 12..<20: return .average
        case 20..<30: return .good
        case 30..<40: return .veryGood
        default: return .excellent
        }
    }
    
    // MARK: - Display Properties
    
    public var color: Color {
        switch self {
        case .poor: return .red
        case .average: return .orange
        case .good: return .yellow
        case .veryGood: return .green
        case .excellent: return .mint
        }
    }
    
    /// Short description for context menu.
    /// Describes current heart rate recovery state without coaching.
    public var description: String {
        switch self {
        case .poor:
            return "Slow heart rate recovery. May indicate fatigue or stress."
        case .average:
            return "Typical heart rate recovery within expected range."
        case .good:
            return "Faster-than-average heart rate recovery."
        case .veryGood:
            return "Rapid heart rate recovery after exercise."
        case .excellent:
            return "Very rapid heart rate recovery. Strong autonomic response."
        }
    }
    
    public var valueRange: Range<Int> {
        switch self {
        case .poor: return 0..<12
        case .average: return 12..<20
        case .good: return 20..<30
        case .veryGood: return 30..<40
        case .excellent: return 40..<Int.max
        }
    }
}
