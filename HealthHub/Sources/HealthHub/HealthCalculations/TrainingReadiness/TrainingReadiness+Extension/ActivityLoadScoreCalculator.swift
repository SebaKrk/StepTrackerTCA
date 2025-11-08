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
    /// determine recovery status and current training readiness.
    /// Lower previous day loads indicate better recovery and higher readiness.
    ///
    /// - Returns: `TrainingComponentScore` with load contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - Complete rest day (0-15%): +3 points (fully recovered)
    /// - Active recovery (15-45%): +5 points (optimal - fresh legs!)
    /// - Light training (45-80%): +2 points (well recovered)
    /// - Normal training (80-130%): 0 points (neutral readiness)
    /// - Heavy training (130-180%): -5 points (moderate fatigue)
    /// - Very heavy training (180%+): -10 points (significant fatigue, recovery needed)
    func calculateActivityLoadScore() async throws -> TrainingComponentScore? {
        guard let yesterdayLoad = try await personalDataManager.getYesterdayActiveEnergy() else {
            return nil
        }
        
        let baselineLoad = try await personalDataManager.getAverageDailyActiveEnergy(days: 7)
        
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
    
    /// Calculates training readiness score based on previous day load compared to baseline.
    ///
    /// Lower previous day loads indicate better recovery and readiness for training.
    /// Higher loads suggest residual fatigue and need for recovery.
    ///
    /// - Parameters:
    ///   - current: Yesterday's active energy burned in kcal
    ///   - baseline: Average daily active energy (7-day baseline) in kcal
    /// - Returns: Score from -10 to +5 based on recovery status
    private func calculateLoadComponentScore(current: Double, baseline: Double?) -> Int {
        guard let baseline = baseline else {
            return 0
        }
        let percentageOfBaseline = (current / baseline) * 100
        switch percentageOfBaseline {
        case 0..<15:
            return 3
        case 15..<45:
            return 5
        case 45..<80:
            return 2
        case 80..<130:
            return 0
        case 130..<180:
            return -5
        case 180...:
            return -10
        default:
            return 0
        }
    }
}
