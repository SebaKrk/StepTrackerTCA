//
//  ReadinessLevel.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 27/09/2025.
//
import SwiftUI

/// Represents the user's training readiness level based on physiological and recovery metrics.
///
/// `ReadinessLevel` categorizes training readiness into five distinct levels, each with
/// associated score ranges, colors for UI representation, and recommended training intensities.
///
/// ## Usage
/// ```swift
/// let level = ReadinessLevel(from: 70) // .good
/// print(level.range) // 60...79
/// ```
///
/// ## Score Ranges
/// The scale is centred on 50: a day where every component sits on its own
/// baseline scores 50 and reads as **Fair**, not as a warning.
///
/// - **Excellent (80-100)**: Optimal readiness for high-intensity training
/// - **Good (60-79)**: Ready for moderate to high-intensity sessions
/// - **Fair (45-59)**: A normal day — train as planned
/// - **Poor (30-44)**: Active recovery or light exercise recommended
/// - **Very Poor (0-29)**: Rest day strongly recommended
public enum ReadinessLevel: String, CaseIterable, Sendable {

    case veryPoor
    case poor
    case fair
    case good
    case excellent

    /// Title key for localization
    public var title: String {
        switch self {
        case .veryPoor: return String(localized: "Very Poor", bundle: .module)
        case .poor: return String(localized: "Poor", bundle: .module)
        case .fair: return String(localized: "Fair", bundle: .module)
        case .good: return String(localized: "Good", bundle: .module)
        case .excellent: return String(localized: "Excellent", bundle: .module)
        }
    }

    /// Creates a ReadinessLevel from a numerical score (0-100).
    ///
    /// - Parameter value: Training readiness score from 0 to 100
    /// - Returns: Corresponding ReadinessLevel enum case
    public init(from value: Int) {
        switch value {
        case 80...:
            self = .excellent
        case 60..<80:
            self = .good
        case 45..<60:
            self = .fair
        case 30..<45:
            self = .poor
        default:
            self = .veryPoor
        }
    }

    /// Color representation for UI display.
    ///
    /// Returns appropriate SwiftUI Color for each readiness level:
    /// - Excellent: Green
    /// - Good: Mint
    /// - Fair: Yellow
    /// - Poor: Orange
    /// - Very Poor: Red
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

    /// The score range associated with this readiness level.
    ///
    /// - Returns: ClosedRange representing the score boundaries for this level
    public var range: ClosedRange<Int> {
        switch self {
        case .excellent:
            return 80...100
        case .good:
            return 60...79
        case .fair:
            return 45...59
        case .poor:
            return 30...44
        case .veryPoor:
            return 0...29
        }
    }

    /// Continuous bounds for charting, where each level ends where the next begins.
    ///
    /// `range` leaves a one-point gap between levels, which would draw as a seam
    /// in a bar or ring. Charts use this instead, so the scale is defined once
    /// here rather than copied into every chart that draws it.
    public var chartRange: ClosedRange<Double> {
        switch self {
        case .excellent:
            return 80...100
        case .good:
            return 60...80
        case .fair:
            return 45...60
        case .poor:
            return 30...45
        case .veryPoor:
            return 0...30
        }
    }

    /// The score a day lands on when every component sits on its baseline.
    public static let neutralScore = 50
}
