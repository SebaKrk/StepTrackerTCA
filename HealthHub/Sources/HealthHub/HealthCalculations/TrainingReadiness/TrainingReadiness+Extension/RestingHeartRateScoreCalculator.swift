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
    /// Compares current resting heart rate against a 7-day baseline to determine
    /// cardiovascular recovery status. Lower RHR relative to baseline indicates
    /// better recovery and training readiness.
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
        // Fetch current RHR (most recent day)
        guard let currentRHR = try await personalDataManager.getRestingHeartRate(days: 1) else {
            return nil
        }
        
        // Fetch baseline (7-day average)
        let baselineRHR = try await personalDataManager.getRestingHeartRate(days: 7)
        
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
    ///   - current: Current resting heart rate in bpm
    ///   - baseline: Baseline (7-day average) resting heart rate in bpm
    /// - Returns: Score from -15 to +15 based on RHR deviation
    private func calculateHeartRateScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            print("    ⚠️ RHR: No baseline available, returning 0")
            return 0
        }
        
        let difference = current - baseline
        print("    📊 RHR: Current=\(current), Baseline=\(baseline), Diff=\(difference)")
        
        switch difference {
        case let diff where diff > 5:
            print("    ❌ RHR: Significantly elevated (+\(diff) bpm)")
            return -15
        case let diff where diff > 2:
            print("    ⚠️ RHR: Moderately elevated (+\(diff) bpm)")
            return -5
        case let diff where diff < -3:
            print("    ✅ RHR: Significantly lower (\(diff) bpm)")
            return 15
        case let diff where diff < -1:
            print("    ✅ RHR: Moderately lower (\(diff) bpm)")
            return 5
        default:
            
            return 0
        }
    }
}
