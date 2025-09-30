//
//  SleepScoreCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import Foundation
import SharedModels

// MARK: - Sleep Quality Score Calculation

extension DefaultTrainingReadinessCalculator {
    
    /// Calculates training readiness score based on sleep duration and quality.
    ///
    /// Evaluates last night's sleep duration against optimal ranges and recent averages
    /// to determine recovery quality. Adequate sleep is critical for training readiness.
    ///
    /// - Returns: `TrainingComponentScore` with sleep contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - 7-9 hours of sleep: +10 points (optimal)
    /// - 6-7 or 9-10 hours: +5 points (acceptable)
    /// - Less than 6 or more than 10 hours: -10 points (suboptimal)
    /// - Additional points based on comparison to personal baseline
    func calculateSleepScore() async throws -> TrainingComponentScore? {
        
        guard let currentSleep = try await sleepDataManager.getLastNightSleep() else {
            return nil
        }
        
        // Fetch baseline (7-night average)
        let baselineSleep = try await sleepDataManager.getAverageSleepFromLastNights(nights: 7)
        
        // Calculate score
        let score = calculateSleepComponentScore(
            current: currentSleep.value,
            baseline: baselineSleep?.value
        )
        
        return TrainingComponentScore(
            score: score,
            currentValue: currentSleep.value,
            baselineValue: baselineSleep?.value,
            unit: "hours"
        )
    }
    
    /// Calculates score based on sleep duration and comparison to baseline.
    ///
    /// - Parameters:
    ///   - current: Last night's sleep duration in hours
    ///   - baseline: Average sleep duration in hours (7-night baseline)
    /// - Returns: Score from -10 to +15 based on sleep quality
    private func calculateSleepComponentScore(current: Double, baseline: Double?) -> Int {
        print("    📊 Sleep: Current=\(current)h, Baseline=\(baseline ?? 0)h")
        
        var score = 0
        
        // Score based on absolute duration (optimal sleep ranges)
        switch current {
        case 7.0...9.0:
            score += 10
            print("    ✅ Sleep: Optimal duration (7-9h)")
        case 6.0..<7.0, 9.0...10.0:
            score += 5
            print("    ⚪ Sleep: Acceptable duration")
        default:
            score -= 10
            print("    ❌ Sleep: Suboptimal duration (<6h or >10h)")
        }
        
        // Additional score based on baseline comparison
        if let baseline = baseline {
            let difference = current - baseline
            
            switch difference {
            case let diff where diff > 1.0:
                score += 5
                print("    ✅ Sleep: Slept more than usual (+\(diff)h)")
            case let diff where diff < -1.5:
                score -= 5
                print("    ⚠️ Sleep: Significantly less than usual (\(diff)h)")
            default:
                print("    ⚪ Sleep: Within normal range vs baseline")
            }
        }
        
        print("    Final Sleep Score: \(score)")
        return score
    }
}
