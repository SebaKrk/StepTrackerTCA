import Foundation

/// Typed WOD score — replaces free-form `score: String`.
public enum WodScoreResult: Codable, Sendable, Equatable {
    case forTime(time: TimeInterval)
    case timeCap(capSeconds: Int, remainingReps: Int)
    case amrap(rounds: Int, extraReps: Int)
    case forLoad(weight: Double)
    case forReps(reps: Int)
    case completed
    case custom(String)

    public var displayString: String {
        switch self {
        case .forTime(let t):
            let minutes = Int(t) / 60
            let seconds = Int(t) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .timeCap(let cap, let reps):
            return "TC \(cap / 60)' + \(reps) reps"
        case .amrap(let r, let extra):
            return "\(r) rds + \(extra) reps"
        case .forLoad(let w):
            return "\(Int(w)) kg"
        case .forReps(let r):
            return "\(r) reps"
        case .completed:
            return "✓"
        case .custom(let s):
            return s
        }
    }
}
