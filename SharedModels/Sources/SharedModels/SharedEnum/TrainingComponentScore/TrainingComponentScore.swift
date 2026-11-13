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
    
    /// Timestamp when this measurement was taken.
    ///
    /// Provides transparency about data freshness. Used to display relative time ("Dziś o 8:07")
    /// in the UI. May be nil for compatibility with existing code.
    public let timestamp: Date?

    /// Average over a long window, where one is meaningful.
    ///
    /// `baselineValue` says what is normal for this user; this says whether that
    /// normal is itself enough. A differential score cannot see a habit, because
    /// the habit is the baseline it compares against — only a longer window and an
    /// outside standard can. Today only sleep sets it.
    public let longTermValue: Double?

    /// Lowest long-term average that still supports recovery, where one exists.
    ///
    /// Kept beside the value rather than in the view: the threshold is a fact
    /// about the signal, not about how it is drawn.
    public let longTermMinimum: Double?

    /// Whether this user's own norm for the signal sits below that minimum.
    ///
    /// Never affects the score. A habit is not an event of today, so charging it
    /// points every morning would make the score stop describing today — which is
    /// the mistake the absolute sleep bands used to make.
    public var isLongTermBelowMinimum: Bool {
        guard let longTermValue, let longTermMinimum else { return false }

        return longTermValue < longTermMinimum
    }
    
    /// Creates a new TrainingComponentScore.
    ///
    /// - Parameters:
    ///   - score: Component score within the range [minScore...maxScore]
    ///   - currentValue: Current measured value
    ///   - baselineValue: Optional baseline for comparison
    ///   - unit: Unit of measurement string
    ///   - minScore: Minimum possible score for this component
    ///   - maxScore: Maximum possible score for this component
    ///   - timestamp: Optional timestamp when measurement was taken
    ///   - longTermValue: Optional average over a long window
    ///   - longTermMinimum: Optional lowest healthy long-term average
    public init(
        score: Int,
        currentValue: Double,
        baselineValue: Double?,
        unit: String,
        minScore: Int,
        maxScore: Int,
        timestamp: Date? = nil,
        longTermValue: Double? = nil,
        longTermMinimum: Double? = nil
    ) {
        self.score = score
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.unit = unit
        self.minScore = minScore
        self.maxScore = maxScore
        self.timestamp = timestamp
        self.longTermValue = longTermValue
        self.longTermMinimum = longTermMinimum
    }
}

// MARK: - Score Status

extension TrainingComponentScore {
    
    /// Share of a component's own range above which its effect counts as strong.
    static let strongEffectShare = 0.7

    /// The score range split into the five statuses, lowest first.
    ///
    /// The gauge behind a score and the label beside it have to agree, and the
    /// only way to guarantee that is to draw both from one set of thresholds.
    /// Scores are integers, so the neutral band is one point wide around zero and
    /// renders as a tick rather than a stripe.
    public var statusBands: [StatusBand] {
        let low = Double(minScore)
        let high = Double(maxScore)
        let strongLow = (low * Self.strongEffectShare).rounded(.up) - 0.5
        let strongHigh = (high * Self.strongEffectShare).rounded(.up) - 0.5

        return [
            StatusBand(status: .stronglyLowers, range: (low - 0.5)...strongLow),
            StatusBand(status: .lowers, range: strongLow...(-0.5)),
            StatusBand(status: .neutral, range: (-0.5)...0.5),
            StatusBand(status: .raises, range: 0.5...strongHigh),
            StatusBand(status: .stronglyRaises, range: strongHigh...(high + 0.5))
        ]
    }

    /// How this component moves today's readiness.
    ///
    /// Derived from the sign of the score, not from its position in the range:
    /// zero means the component sits on its own baseline, which is neutral and
    /// has to read as neutral. Splitting the range into quartiles put zero in the
    /// second one, so the most ordinary outcome was shown as a warning.
    ///
    /// Strength is measured against the component's own headroom, because they
    /// are not comparable: activity can only contribute +5 where sleep can give
    /// +15, so a flat point threshold would call the same effort strong in one
    /// component and marginal in another.
    public var status: ScoreStatus {
        guard score != 0 else { return .neutral }

        if score > 0 {
            let strongFrom = Double(maxScore) * Self.strongEffectShare

            return Double(score) >= strongFrom ? .stronglyRaises : .raises
        }

        let strongFrom = Double(minScore) * Self.strongEffectShare

        return Double(score) <= strongFrom ? .stronglyLowers : .lowers
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

