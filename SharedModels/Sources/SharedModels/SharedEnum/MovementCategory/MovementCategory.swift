import Foundation
import SwiftUI

public enum MovementCategory: String, CaseIterable, Codable, Sendable {
    case strength
    case olympicLifting
    case gymnastics
    case cardio
    case mobility
    case mixed

    public var displayName: String {
        switch self {
        case .strength:       return String(localized: "Strength", bundle: .module)
        case .olympicLifting: return String(localized: "Weightlifting", bundle: .module)
        case .gymnastics:     return String(localized: "Gymnastics", bundle: .module)
        case .cardio:         return String(localized: "Cardio", bundle: .module)
        case .mobility:       return String(localized: "Mobility", bundle: .module)
        case .mixed:          return String(localized: "Mixed", bundle: .module)
        }
    }

    public var color: Color {
        switch self {
        case .strength:       return .orange
        case .olympicLifting: return .purple
        case .gymnastics:     return .blue
        case .cardio:         return .green
        case .mobility:       return .mint
        case .mixed:          return .red
        }
    }
}
