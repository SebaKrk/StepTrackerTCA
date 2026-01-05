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
/// let level = ReadinessLevel(from: 75) // .good
/// print(level.range) // 70...84
/// ```
///
/// ## Score Ranges
/// - **Excellent (85-100)**: Optimal readiness for high-intensity training
/// - **Good (70-84)**: Ready for moderate to high-intensity sessions
/// - **Fair (55-69)**: Suitable for light to moderate training
/// - **Poor (40-54)**: Active recovery or light exercise recommended
/// - **Very Poor (0-39)**: Rest day strongly recommended
public enum ReadinessLevel: String, CaseIterable, Sendable {
    
    case veryPoor = "Very Poor"
    
    case poor = "Poor"
    
    case fair = "Fair"
    
    case good = "Good"
    
    case excellent = "Excellent"
    
    /// Localized name of the readiness level
    public var localizedName: String {
        String(localized: String.LocalizationValue(rawValue), bundle: .module)
    }
    
    /// Creates a ReadinessLevel from a numerical score (0-100).
    ///
    /// - Parameter value: Training readiness score from 0 to 100
    /// - Returns: Corresponding ReadinessLevel enum case
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
