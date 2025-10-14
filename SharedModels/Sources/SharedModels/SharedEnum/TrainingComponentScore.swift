//
//  TrainingComponentScore.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Foundation

/// Represents a single component's contribution to training readiness calculation.
///
/// `TrainingComponentScore` encapsulates the scoring and contextual data for individual
/// metrics that contribute to overall training readiness. Each component provides both
/// the calculated score and the underlying data for transparency and debugging.
///
/// ## Usage
/// ```swift
/// let heartRateScore = TrainingComponentScore(
///     score: 10,
///     currentValue: 52.0,
///     baselineValue: 55.0,
///     unit: "bpm",
///     minScore: -15,
///     maxScore: 15
/// )
/// ```
///
/// ## Score Range
/// Each component has its own score range defined by `minScore` and `maxScore`:
/// - Positive scores indicate favorable conditions for training
/// - Negative scores suggest suboptimal conditions
/// - Zero represents neutral/baseline conditions
///
/// Typical ranges by component:
/// - Activity Load: -10 to +5
/// - HRV: -15 to +15
/// - Resting Heart Rate: -15 to +15
/// - Sleep Quality: -10 to +15
public struct TrainingComponentScore: Sendable, Equatable {
    
    /// Component score contribution to overall training readiness.
    ///
    /// The actual score value within the range defined by `minScore` and `maxScore`.
    /// Positive values indicate favorable conditions, negative values suggest caution.
    public let score: Int
    
    /// Current measured value for this component.
    ///
    /// The raw measurement value in the component's native unit (e.g., 52.0 for heart rate in bpm).
    public let currentValue: Double
    
    /// Baseline value for comparison (typically a recent average).
    ///
    /// Used to contextualize the current value. May be nil if insufficient historical data exists.
    /// Often represents a 7-day average or similar baseline period.
    public let baselineValue: Double?
    
    /// Unit of measurement for this component.
    ///
    /// Human-readable unit string (e.g., "bpm", "ms", "hours", "kcal") for display purposes.
    public let unit: String
    
    /// Minimum possible score for this component.
    ///
    /// Represents the most unfavorable score this component can contribute (typically negative).
    public let minScore: Int
    
    /// Maximum possible score for this component.
    ///
    /// Represents the most favorable score this component can contribute (typically positive).
    public let maxScore: Int
    
    /// Creates a new TrainingComponentScore.
    ///
    /// - Parameters:
    ///   - score: Component score within the range [minScore...maxScore]
    ///   - currentValue: Current measured value
    ///   - baselineValue: Optional baseline for comparison
    ///   - unit: Unit of measurement string
    ///   - minScore: Minimum possible score for this component
    ///   - maxScore: Maximum possible score for this component
    public init(
        score: Int,
        currentValue: Double,
        baselineValue: Double?,
        unit: String,
        minScore: Int,
        maxScore: Int
    ) {
        self.score = score
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.unit = unit
        self.minScore = minScore
        self.maxScore = maxScore
    }
}
