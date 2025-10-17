//
//  HRVScoreCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

// MARK: - Heart Rate Variability Score Calculation

extension DefaultTrainingReadinessCalculator {
    
    /// Calculates training readiness score based on heart rate variability data.
    ///
    /// Compares current HRV against a 7-day baseline to assess autonomic nervous
    /// system balance and recovery. Higher HRV relative to baseline indicates
    /// better parasympathetic activity and training readiness.
    ///
    /// - Returns: `TrainingComponentScore` with HRV contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - HRV significantly higher than baseline: +15 points (excellent autonomic balance)
    /// - HRV moderately higher: +10 points (good recovery)
    /// - HRV within normal range: 0 points (neutral)
    /// - HRV moderately lower: -10 points (suboptimal recovery)
    /// - HRV significantly lower: -15 points (poor autonomic balance)
    func calculateHRVScore() async throws -> TrainingComponentScore? {
        // Fetch current HRV (most recent day)
        guard let currentHRV = try await personalDataManager.getHeartRateVariability(days: 1) else {
            return nil
        }
        
        // Fetch baseline (7-day average)
        let baselineHRV = try await personalDataManager.getHeartRateVariability(days: 7)
        
        // Calculate score
        let score = calculateHRVComponentScore(
            current: currentHRV.value,
            baseline: baselineHRV?.value
        )
        
        return TrainingComponentScore(
            score: score,
            currentValue: currentHRV.value,
            baselineValue: baselineHRV?.value,
            unit: "ms",
            minScore: -15,
            maxScore: 15    
        )
    }
    
    /// Calculates score based on difference between current and baseline HRV.
    ///
    /// Note: Unlike resting heart rate, higher HRV indicates better readiness.
    ///
    /// - Parameters:
    ///   - current: Current HRV in milliseconds
    ///   - baseline: Baseline (7-day average) HRV in milliseconds
    /// - Returns: Score from -15 to +15 based on HRV deviation
    private func calculateHRVComponentScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            print("    ⚠️ HRV: No baseline available, returning 0")
            return 0
        }
        
        let difference = current - baseline
        print("    📊 HRV: Current=\(current)ms, Baseline=\(baseline)ms, Diff=\(difference)ms")
        
        switch difference {
        case let diff where diff > 10:
            print("    ✅ HRV: Significantly higher (+\(diff) ms)")
            return 15
        case let diff where diff > 5:
            print("    ✅ HRV: Moderately higher (+\(diff) ms)")
            return 10
        case let diff where diff < -10:
            print("    ❌ HRV: Significantly lower (\(diff) ms)")
            return -15
        case let diff where diff < -5:
            print("    ⚠️ HRV: Moderately lower (\(diff) ms)")
            return -10
        default:
            print("    ⚪ HRV: Within normal range default (0 ms)")
            return 0
        }
    }
}
