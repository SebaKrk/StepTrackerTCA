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
public enum HRRecoveryLevel: CaseIterable, Identifiable, Sendable {
    
    case poor             // < 12 bpm
    case average          // 12–20 bpm
    case good             // 20–30 bpm
    case veryGood         // 30–40 bpm
    case excellent        // > 40 bpm
    
    public var id: String { title }
    
    /// Title key for localization
    public var title: String {
        switch self {
        case .poor: return String(localized: "Poor", bundle: .module)
        case .average: return String(localized: "Average", bundle: .module)
        case .good: return String(localized: "Good", bundle: .module)
        case .veryGood: return String(localized: "Very Good", bundle: .module)
        case .excellent: return String(localized: "Excellent", bundle: .module)
        }
    }
    
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
            return String(localized: "Slow heart rate recovery. May indicate fatigue or stress.", bundle: .module)
        case .average:
            return String(localized: "Typical heart rate recovery within expected range.", bundle: .module)
        case .good:
            return String(localized: "Faster-than-average heart rate recovery.", bundle: .module)
        case .veryGood:
            return String(localized: "Rapid heart rate recovery after exercise.", bundle: .module)
        case .excellent:
            return String(localized: "Very rapid heart rate recovery. Strong autonomic response.", bundle: .module)
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
