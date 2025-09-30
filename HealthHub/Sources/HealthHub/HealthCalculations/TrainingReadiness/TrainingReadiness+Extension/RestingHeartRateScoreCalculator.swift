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
    /// Compares this morning's resting heart rate against a 7-day baseline to determine
    /// cardiovascular recovery status. Lower RHR relative to baseline indicates
    /// better recovery and training readiness.
    ///
    /// ## Time Windows
    /// - Current: This morning (4 AM - 11 AM today) - first measurement after waking
    /// - Baseline: Average of morning RHR from last 7 days
    ///
    /// - Returns: `TrainingComponentScore` with RHR contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - RHR significantly lower than baseline: +15 points (excellent recovery)
    /// - RHR moderately lower: +5 points (good recovery)
    /// - RHR within normal range: 0 points (neutral)
    /// - RHR moderately elevated: -5 points (suboptimal recovery)
    /// - RHR significantly elevated: -15 points (poor recovery)
    func calculateRestingHeartRateScore() async throws -> TrainingComponentScore? {
        // Fetch this morning's RHR
        guard let currentRHR = try await personalDataManager.getThisMorningRestingHeartRate() else {
            return nil
        }
        
        // Fetch baseline (7-day morning average)
        let baselineRHR = try await personalDataManager.getAverageMorningRestingHeartRate(days: 7)
        
        // Calculate score
        let score = calculateHeartRateScore(
            current: currentRHR.value,
            baseline: baselineRHR?.value
        )
        
        return TrainingComponentScore(
            score: score,
            currentValue: currentRHR.value,
            baselineValue: baselineRHR?.value,
            unit: "bpm"
        )
    }
    
    /// Calculates score based on difference between current and baseline RHR.
    ///
    /// - Parameters:
    ///   - current: This morning's resting heart rate in bpm
    ///   - baseline: Baseline (7-day morning average) resting heart rate in bpm
    /// - Returns: Score from -15 to +15 based on RHR deviation
    private func calculateHeartRateScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            return 0
        }
        
        let difference = current - baseline
        
        switch difference {
        case let diff where diff > 5:
            return -15 // Significantly elevated HR = poor readiness
        case let diff where diff > 2:
            return -5  // Moderately elevated HR = suboptimal
        case let diff where diff < -3:
            return 15  // Significantly lower HR = excellent readiness
        case let diff where diff < -1:
            return 5   // Moderately lower HR = good readiness
        default:
            return 0   // Within normal range
        }
    }
}
