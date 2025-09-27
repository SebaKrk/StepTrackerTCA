//
//  ReadinessLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 27/09/2025.
//

import SwiftUI

public enum ReadinessLevel: String, CaseIterable {
    case veryPoor = "Very Poor"
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
    
    public init(from value: Int) {
        switch value {
        case 85...100:
            self = .excellent
        case 70..<85:
            self = .good
        case 55..<70:
            self = .fair
        case 40..<55:
            self = .poor
        default:
            self = .veryPoor
        }
    }
    
    public var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .mint
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .veryPoor:
            return .red
        }
    }
    
    public var range: ClosedRange<Int> {
        switch self {
        case .excellent:
            return 85...100
        case .good:
            return 70...84
        case .fair:
            return 55...69
        case .poor:
            return 40...54
        case .veryPoor:
            return 0...39
        }
    }
}
