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
/// after stopping exercise. Faster recovery indicates better cardiovascular fitness.
public enum HRRecoveryLevel: String, CaseIterable, Identifiable, Sendable {
    
    case poor = "Poor"             // < 12 bpm
    case average = "Average"       // 12-20 bpm
    case good = "Good"             // 20-30 bpm
    case veryGood = "Very Good"    // 30-40 bpm
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
    
    public var description: String {
        switch self {
        case .poor:
            return "Below average cardiovascular fitness, consider aerobic training"
        case .average:
            return "Normal recovery rate, typical for moderately active individuals"
        case .good:
            return "Good cardiovascular fitness, above average recovery"
        case .veryGood:
            return "Very good fitness level, efficient cardiac recovery"
        case .excellent:
            return "Excellent cardiovascular conditioning, athlete-level recovery"
        }
    }
    
    public var recommendation: String {
        switch self {
        case .poor:
            return "Focus on consistent low-intensity aerobic exercise to improve cardiac efficiency"
        case .average:
            return "Continue regular cardio training to maintain and improve recovery"
        case .good:
            return "Your training is paying off, maintain current cardio routine"
        case .veryGood:
            return "Excellent progress, consider adding variety to prevent plateau"
        case .excellent:
            return "Peak cardiovascular fitness, focus on maintenance and recovery"
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
