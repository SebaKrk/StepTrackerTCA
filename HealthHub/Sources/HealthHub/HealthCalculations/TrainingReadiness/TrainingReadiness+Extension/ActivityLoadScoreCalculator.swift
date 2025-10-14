//
//  ActivityLoadScoreCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

// MARK: - Activity Load Score Calculation

extension DefaultTrainingReadinessCalculator {
    
    /// Calculates training readiness score based on previous day's training load.
    ///
    /// Evaluates yesterday's active energy expenditure against recent averages to
    /// determine if residual fatigue might impact current training readiness.
    /// High training loads require adequate recovery time.
    ///
    /// - Returns: `TrainingComponentScore` with load contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - Load significantly below average: -5 points (detraining risk)
    /// - Load within normal range: +5 points (optimal)
    /// - Load moderately above average: 0 points (manageable)
    /// - Load significantly above average: -10 points (insufficient recovery time)
    func calculateActivityLoadScore() async throws -> TrainingComponentScore? {
        // Fetch yesterday's active energy (full day: 00:00 - 23:59)
        guard let yesterdayLoad = try await personalDataManager.getYesterdayActiveEnergy() else {
            return nil
        }
        
        // Fetch baseline (7-day average)
        let baselineLoad = try await personalDataManager.getAverageDailyActiveEnergy(days: 7)
        
        // Calculate score
        let score = calculateLoadComponentScore(
            current: yesterdayLoad.value,
            baseline: baselineLoad?.value
        )
        
        return TrainingComponentScore(
            score: score,
            currentValue: yesterdayLoad.value,
            baselineValue: baselineLoad?.value,
            unit: "kcal",
            minScore: -10,
            maxScore: 5
        )
    }
    
    /// Calculates score based on previous day load compared to baseline.
    ///
    /// - Parameters:
    ///   - current: Yesterday's active energy burned in kcal
    ///   - baseline: Average daily active energy (7-day baseline) in kcal
    /// - Returns: Score from -10 to +5 based on training load
    private func calculateLoadComponentScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            print("    ⚠️ Activity: No baseline available, returning 0")
            return 0
        }
        
        let percentageOfBaseline = (current / baseline) * 100
        print("    📊 Activity: Yesterday=\(current)kcal, Baseline=\(baseline)kcal, Percentage=\(percentageOfBaseline)%")
        
        switch percentageOfBaseline {
        case 0..<50:
            print("    ❌ Activity: Too little activity (detraining risk)")
            return -5
        case 50..<120:
            print("    ✅ Activity: Normal activity range")
            return 5
        case 120..<150:
            print("    ⚪ Activity: Moderately high load")
            return 0
        case 150...:
            print("    ❌ Activity: Very high load (needs recovery)")
            return -10
        default:
            return 0
        }
    }
}
