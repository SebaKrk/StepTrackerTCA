//
//  RestingHeartRateScoreCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

// MARK: - Resting Heart Rate Score Calculation

extension DefaultTrainingReadinessCalculator {

    /// Calculates training readiness score based on resting heart rate data.
    ///
    /// Compares the night's resting heart rate against a 7-day baseline to determine
    /// cardiovascular recovery status. Lower RHR relative to baseline indicates
    /// better recovery and training readiness.
    ///
    /// ## Time Windows
    /// - Current: the night being assessed, plus a grace period for the Watch to write it
    /// - Baseline: same window across the 7 preceding days, excluding the day being scored
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: `TrainingComponentScore` with RHR contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - RHR significantly lower than baseline: +15 points (excellent recovery)
    /// - RHR moderately lower: +5 points (good recovery)
    /// - RHR within normal range: 0 points (neutral)
    /// - RHR moderately elevated: -5 points (suboptimal recovery)
    /// - RHR significantly elevated: -15 points (poor recovery)
    func calculateRestingHeartRateScore(for day: ReadinessDay) async throws -> TrainingComponentScore? {
        let window = TrainingReadinessTimeWindows.restingHeartRateWindow(for: day)

        guard let currentRHR = try await personalDataManager.getRestingHeartRate(in: window) else {
            return nil
        }

        let baselineWindows = TrainingReadinessTimeWindows.previousRestingHeartRateWindows(
            count: baselineDayCount,
            before: day
        )
        let baselineRHR = try await personalDataManager.getAverageRestingHeartRate(in: baselineWindows)

        let score = calculateHeartRateScore(
            current: currentRHR.value,
            baseline: baselineRHR?.value
        )

        return TrainingComponentScore(
            score: score,
            currentValue: currentRHR.value,
            baselineValue: baselineRHR?.value,
            unit: "bpm",
            minScore: -15,
            maxScore: 15,
            timestamp: currentRHR.date
        )
    }

    /// Calculates score based on difference between current and baseline RHR.
    ///
    /// - Parameters:
    ///   - current: The night's resting heart rate in bpm
    ///   - baseline: Baseline (7-day average) resting heart rate in bpm
    /// - Returns: Score from -15 to +15 based on RHR deviation
    private func calculateHeartRateScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            return 0
        }

        let difference = current - baseline

        switch difference {
        case let diff where diff > 5:
            return -15
        case let diff where diff > 2:
            return -5
        case let diff where diff < -3:
            return 15
        case let diff where diff < -1:
            return 5
        default:
            return 0
        }
    }
}
