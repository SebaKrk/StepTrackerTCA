import Foundation

/// How the athlete performed the workout relative to the prescribed weights/movements.
public enum ScalingType: String, CaseIterable, Codable, Sendable {
    case rx
    case scaled
    case rxPlus

    public var displayName: String {
        switch self {
        case .rx:     return "Rx"
        case .scaled: return "Scaled"
        case .rxPlus: return "Rx+"
        }
    }
}
