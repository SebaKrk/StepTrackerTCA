//
//  TrainingReadinessCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import Foundation
import SharedModels

/// Protocol defining methods for calculating and retrieving training readiness data.
///
/// `TrainingReadinessCalculator` provides a standardized interface for computing training
/// readiness scores based on physiological metrics like heart rate, sleep, and activity data.
/// Implementations should aggregate multiple health indicators to provide actionable
/// training guidance.
///
/// ## Overview
/// Training readiness calculation involves analyzing:
/// - Resting heart rate trends
/// - Heart rate variability (HRV)
/// - Sleep quality and duration
/// - Previous day training load
/// - Recovery indicators
///
/// ## Usage
/// ```swift
/// let calculator = DefaultTrainingReadinessCalculator()
///
/// // Get current training readiness
/// let readiness = try await calculator.calculateTrainingReadiness()
/// print("Readiness: \(readiness.overallScore)/100 (\(readiness.readinessLevel))")
///
/// // Get historical data
/// let history = try await calculator.getTrainingReadinessHistory(days: 7)
/// ```
///
/// ## Implementation Notes
/// Implementations should:
/// - Handle missing data gracefully by marking results as unreliable
/// - Use appropriate baseline periods for comparison (typically 7-14 days)
/// - Weight different components based on data quality and relevance
/// - Provide consistent scoring across different users and conditions
public protocol TrainingReadinessCalculator: Sendable {
    
    /// Calculates readiness for the current day, or says why it cannot.
    ///
    /// Returns an outcome rather than a result, because "the night is not over
    /// yet" is a normal state with a different answer for the user than missing
    /// permissions — and neither can be told apart by counting `nil` components.
    ///
    /// - Returns: A `ReadinessOutcome` carrying the score or the reason there is none
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Data Requirements
    /// While the calculation can work with partial data, optimal results require:
    /// - At least 7 days of baseline heart rate data
    /// - A completed sleep session for the current night
    /// - Activity data from previous day
    /// - HRV data (if available)
    func calculateReadinessOutcome() async throws -> ReadinessOutcome
    
    /// Retrieves historical training readiness data for trend analysis.
    ///
    /// Provides a time series of training readiness calculations, useful for identifying
    /// patterns, tracking recovery, and understanding long-term trends in readiness.
    ///
    /// - Parameter days: Number of days of historical data to retrieve (1-90 recommended)
    /// - Returns: Array of `TrainingReadinessResult` ordered chronologically (newest first)
    /// - Throws: HealthKit errors if data access fails, or calculation errors if processing fails
    ///
    /// ## Performance Considerations
    /// - Large day ranges may impact performance due to extensive data processing
    /// - Results are calculated on-demand rather than cached
    /// - Consider limiting requests to reasonable ranges (7-30 days) for optimal UX
    func getTrainingReadinessHistory(days: Int) async throws -> [TrainingReadinessResult]

    /// Rebuilds stored history from HealthKit, when it has not been built for the
    /// current algorithm version.
    ///
    /// A readiness day is derived entirely from HealthKit and from boundaries that
    /// already happened, so scoring a past day gives the same answer today as it
    /// would have given that morning. That makes history recomputable rather than
    /// something that has to accumulate a day at a time.
    ///
    /// Also the answer to a version bump: rows written by older rules are not
    /// comparable with new ones, and this is what makes them comparable again.
    ///
    /// - Returns: How many days were written, zero when nothing was needed
    /// - Throws: HealthKit errors if data access fails
    func rebuildHistoryIfNeeded() async throws -> Int
}





