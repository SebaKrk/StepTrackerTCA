import Foundation
import SwiftUI

public enum MovementCategory: String, CaseIterable, Codable, Sendable {
    case strength
    case olympicLifting
    case gymnastics
    case cardio
    case mixed

    public var displayName: String {
        switch self {
        case .strength:       return "Strength"
        case .olympicLifting: return "Olympic Lifting"
        case .gymnastics:     return "Gymnastics"
        case .cardio:         return "Cardio"
        case .mixed:          return "Mixed"
        }
    }

    public var color: Color {
        switch self {
        case .strength:       return .orange
        case .olympicLifting: return .purple
        case .gymnastics:     return .blue
        case .cardio:         return .green
        case .mixed:          return .red
        }
    }
}
