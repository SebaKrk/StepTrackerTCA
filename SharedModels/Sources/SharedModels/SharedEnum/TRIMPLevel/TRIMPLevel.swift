//
//  TRIMPLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/01/2026.
//

import SwiftUI

/// Training Impulse (TRIMP) classification based on training load.
///
/// TRIMP quantifies training load by combining duration and intensity (heart rate zones).
/// Higher values indicate greater physiological stress requiring longer recovery.
public enum TRIMPLevel: String, CaseIterable, Identifiable, Sendable {
    
    case veryLight = "Very Light"   // < 50
    case light = "Light"            // 50-100
    case moderate = "Moderate"      // 100-150
    case moderateHard = "Moderate-Hard" // 150-200
    case hard = "Hard"              // 200-300
    case veryHard = "Very Hard"     // 300-400
    case extreme = "Extreme"        // > 400
    
    public var id: String { rawValue }
    
    // MARK: - Factory
    
    /// Creates a TRIMPLevel from a raw TRIMP value.
    public static func from(value: Double) -> TRIMPLevel {
        switch value {
        case ..<50: return .veryLight
        case 50..<100: return .light
        case 100..<150: return .moderate
        case 150..<200: return .moderateHard
        case 200..<300: return .hard
        case 300..<400: return .veryHard
        default: return .extreme
        }
    }
    
    // MARK: - Display Properties
    
    public var color: Color {
        switch self {
        case .veryLight: return .mint
        case .light: return .green
        case .moderate: return .yellow
        case .moderateHard: return .orange
        case .hard: return .red
        case .veryHard: return .purple
        case .extreme: return .pink
        }
    }
    
    public var recoveryEstimate: String {
        switch self {
        case .veryLight: return "< 12 hours"
        case .light: return "12-24 hours"
        case .moderate: return "~1 day"
        case .moderateHard: return "1-2 days"
        case .hard: return "2-3 days"
        case .veryHard: return "3-4 days"
        case .extreme: return "4+ days"
        }
    }
    
    public var description: String {
        switch self {
        case .veryLight:
            return "Minimal physiological stress. Perfect for active recovery days or light movement sessions. Your body can handle another session the same day if needed."
            
        case .light:
            return "Low training load typical for easy runs, yoga, or recovery workouts. Builds aerobic base without significant fatigue. Good for maintaining fitness between harder sessions."
            
        case .moderate:
            return "Standard training session with meaningful physiological stimulus. Typical for tempo runs, moderate cycling, or regular gym workouts. The sweet spot for consistent training."
            
        case .moderateHard:
            return "Challenging workout pushing into higher intensities. Expect some residual fatigue next day. Good for building fitness when properly recovered."
            
        case .hard:
            return "Demanding session causing significant physiological stress. Long runs, intense intervals, or race-pace efforts fall here. Requires proper recovery before next hard session."
            
        case .veryHard:
            return "Very high training stress approaching competition levels. Long endurance events or multiple intense sessions. Risk of overtraining if repeated without adequate recovery."
            
        case .extreme:
            return "Exceptional training load - marathon, ultra events, or Ironman-level efforts. Extended recovery essential. Monitor for signs of overreaching in following days."
        }
    }
    
    public var valueRange: ClosedRange<Double> {
        switch self {
        case .veryLight: return 0...50
        case .light: return 50...100
        case .moderate: return 100...150
        case .moderateHard: return 150...200
        case .hard: return 200...300
        case .veryHard: return 300...400
        case .extreme: return 400...1000
        }
    }
    
    /// Recommendation for next training session.
    public var nextSessionRecommendation: String {
        switch self {
        case .veryLight:
            return "Ready for any intensity tomorrow"
        case .light:
            return "Can train normally tomorrow"
        case .moderate:
            return "Light or moderate session tomorrow OK"
        case .moderateHard:
            return "Consider easy session or rest tomorrow"
        case .hard:
            return "Rest or very light activity recommended for 1-2 days"
        case .veryHard:
            return "Prioritize recovery for 2-3 days before next hard effort"
        case .extreme:
            return "Full recovery week recommended, monitor fatigue closely"
        }
    }
}
