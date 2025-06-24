//
//  HeartRateZone.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 24/06/2025.
//

import SwiftUI

public enum HeartRateZone: String, CaseIterable, Identifiable {
    
    case recovery = "Recovery"           // 50-60% HR max
    case fatBurning = "Fat Burning"      // 60-70% HR max
    case aerobic = "Aerobic"             // 70-80% HR max
    case threshold = "Threshold"         // 80-90% HR max
    case anaerobic = "Anaerobic"         // 90-100% HR max
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .recovery: return .blue
        case .fatBurning: return .green
        case .aerobic: return .yellow
        case .threshold: return .orange
        case .anaerobic: return .red
        }
    }
    
    public var description: String {
        switch self {
        case .recovery: return "Light activity, active recovery"
        case .fatBurning: return "Comfortable pace, fat burning"
        case .aerobic: return "Moderate effort, aerobic base"
        case .threshold: return "Hard effort, lactate threshold"
        case .anaerobic: return "Very hard, anaerobic power"
        }
    }
    
    public var percentageRange: ClosedRange<Double> {
        switch self {
        case .recovery: return 0.5...0.6
        case .fatBurning: return 0.6...0.7
        case .aerobic: return 0.7...0.8
        case .threshold: return 0.8...0.9
        case .anaerobic: return 0.9...1.0
        }
    }
    
}
