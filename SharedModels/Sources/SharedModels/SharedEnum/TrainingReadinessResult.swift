//
//  TrainingReadinessResult.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Foundation

/// Comprehensive result of training readiness calculation combining multiple physiological metrics.
///
/// `TrainingReadinessResult` represents the complete output of training readiness analysis,
/// including the overall score, component breakdowns, and metadata about the calculation.
/// This result can be used to guide training decisions and provide detailed feedback to users.
///
/// ## Usage
/// ```swift
/// let result = TrainingReadinessResult(
///     overallScore: 75,
///     components: components,
///     isReliable: true
/// )
///
/// print(result.readinessLevel) // .good
/// print(result.components.restingHeartRate?.score) // 10
/// ```
///
/// ## Score Interpretation
/// The overall score (0-100) is automatically converted to a ReadinessLevel:
/// - 85-100: Excellent readiness
/// - 70-84: Good readiness
/// - 55-69: Fair readiness
/// - 40-54: Poor readiness
/// - 0-39: Very poor readiness
public struct TrainingReadinessResult: Sendable, Equatable {
    
    /// Overall training readiness score from 0 to 100.
    ///
    /// Calculated by combining individual component scores with baseline adjustments.
    /// Higher scores indicate better readiness for intense training.
    public let overallScore: Int
    
    /// Categorized interpretation of the overall score.
    ///
    /// Automatically derived from overallScore using ReadinessLevel(from:) initializer.
    /// Provides a human-readable assessment of training readiness.
    public let readinessLevel: ReadinessLevel
    
    /// Detailed breakdown of individual component contributions.
    ///
    /// Contains scores for resting heart rate, HRV, sleep quality, and previous day load.
    /// Components may be nil if data is unavailable for specific metrics.
    public let components: TrainingReadinessComponents
    
    /// Timestamp when this calculation was performed.
    ///
    /// Defaults to current date/time when TrainingReadinessResult is created.
    /// Useful for tracking calculation history and data freshness.
    public let calculatedAt: Date
    
    /// Indicates whether the result is based on sufficient data.
    ///
    /// False when critical data is missing or when calculation confidence is low.
    /// Should be used to display warnings or caveats to users about result reliability.
    public let isReliable: Bool
    
    /// Creates a new TrainingReadinessResult.
    ///
    /// - Parameters:
    ///   - overallScore: Combined training readiness score (0-100)
    ///   - components: Individual component score breakdown
    ///   - calculatedAt: Calculation timestamp (defaults to current time)
    ///   - isReliable: Whether result is based on sufficient data
    public init(
        overallScore: Int,
        components: TrainingReadinessComponents,
        calculatedAt: Date = Date(),
        isReliable: Bool
    ) {
        self.overallScore = overallScore
        self.readinessLevel = ReadinessLevel(from: overallScore)
        self.components = components
        self.calculatedAt = calculatedAt
        self.isReliable = isReliable
    }
}
