//
//  TrainingComponentScore.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Foundation
import SwiftUI

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

// MARK: - Score Status

extension TrainingComponentScore {
    
    /// Computed status based on the score's position within the min-max range.
    ///
    /// Divides the score range into four equal quartiles:
    /// - Bottom 25%: Poor
    /// - Second 25%: Below Average
    /// - Third 25%: Good
    /// - Top 25%: Excellent
    public var status: ScoreStatus {
        let totalRange = maxScore - minScore
        let quarterRange = Double(totalRange) / 4.0
        
        let boundary1 = minScore + Int(quarterRange)
        let boundary2 = minScore + Int(quarterRange * 2)
        let boundary3 = minScore + Int(quarterRange * 3)
        
        if score <= boundary1 {
            return .poor
        } else if score <= boundary2 {
            return .belowAverage
        } else if score <= boundary3 {
            return .good
        } else {
            return .excellent
        }
    }
}

// MARK: - Activity Status Mapping

extension TrainingComponentScore {
    
    /// Maps the component score to an activity status.
    ///
    /// This should only be used for activity load metrics where `currentValue`
    /// represents calories burned and `baselineValue` represents the 7-day average.
    ///
    /// - Returns: Activity status if baseline is available, nil otherwise
    ///
    /// ## Example
    /// ```swift
    /// if let activityStatus = activityScore.asActivityStatus {
    ///     print(activityStatus.title)  // "Good Readiness"
    /// }
    /// ```
    public var asActivityStatus: ActivityStatus? {
        guard let baseline = baselineValue, baseline > 0 else {
            return nil
        }
        
        let percentageOfBaseline = (currentValue / baseline) * 100
        return ActivityStatus.from(loadPercentage: percentageOfBaseline)
    }
}

// MARK: - Helper Extension

extension TrainingReadinessComponents {
    
    /// Returns the training component score for a specific metric type
    /// - Parameter type: The health metric type to retrieve
    /// - Returns: The corresponding training component score, or nil if unavailable
    public func score(for type: HealthMetricType) -> TrainingComponentScore? {
        switch type {
        case .rhr:
            return restingHeartRate
        case .hrv:
            return heartRateVariability
        case .sleep:
            return sleepQuality
        case .activity:
            return previousDayLoad
        }
    }
}
