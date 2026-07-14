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
    
    /// Calculates current training readiness based on available health data.
    ///
    /// Analyzes recent physiological metrics to determine the user's readiness for training.
    /// The calculation considers multiple factors including heart rate patterns, sleep quality,
    /// recovery indicators, and previous training load.
    ///
    /// - Returns: A `TrainingReadinessResult` containing the overall score, component breakdown,
    ///           and reliability indicators
    /// - Throws: HealthKit errors if data access fails, or calculation errors if processing fails
    ///
    /// ## Data Requirements
    /// While the calculation can work with partial data, optimal results require:
    /// - At least 7 days of baseline heart rate data
    /// - Recent sleep data (last 1-2 nights)
    /// - Activity data from previous day
    /// - HRV data (if available)
    func calculateTrainingReadiness() async throws -> TrainingReadinessResult
    
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
}





