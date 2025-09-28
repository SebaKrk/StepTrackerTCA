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
///     unit: "bpm"
/// )
/// ```
///
/// ## Score Range
/// Component scores typically range from -20 to +20, where:
/// - Positive scores indicate favorable conditions for training
/// - Negative scores suggest suboptimal conditions
/// - Zero represents neutral/baseline conditions
public struct TrainingComponentScore: Sendable, Equatable {
    
    /// Component score contribution to overall training readiness.
    ///
    /// Ranges from -20 to +20, representing this component's impact on training readiness.
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
    
    /// Creates a new TrainingComponentScore.
    ///
    /// - Parameters:
    ///   - score: Component score from -20 to +20
    ///   - currentValue: Current measured value
    ///   - baselineValue: Optional baseline for comparison
    ///   - unit: Unit of measurement string
    public init(
        score: Int,
        currentValue: Double,
        baselineValue: Double?,
        unit: String
    ) {
        self.score = score
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.unit = unit
    }
}
