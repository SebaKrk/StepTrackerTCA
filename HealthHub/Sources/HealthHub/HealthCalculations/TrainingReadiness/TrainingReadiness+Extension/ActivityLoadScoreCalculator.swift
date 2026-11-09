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
    /// Evaluates the preceding day's active energy expenditure against recent averages
    /// to determine recovery status and current training readiness.
    /// Lower previous day loads indicate better recovery and higher readiness.
    ///
    /// - Parameter day: The readiness day being calculated
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
    func calculateActivityLoadScore(for day: ReadinessDay) async throws -> TrainingComponentScore? {
        guard let window = TrainingReadinessTimeWindows.previousDay(
                  for: day,
                  calendar: calendar
              ),
              let previousLoad = try await personalDataManager.getActiveEnergy(in: window) else {
            return nil
        }

        // `skipping: 1` because the measured value IS yesterday — without it the
        // day being scored sits inside its own baseline and dilutes its deviation.
        let baselineWindows = TrainingReadinessTimeWindows.previousDays(
            count: baselinePoolDays,
            before: day,
            skipping: 1,
            calendar: calendar
        )
        let baselineLoad = try await personalDataManager.getAverageActiveEnergy(
            in: baselineWindows,
            takingFirst: baselineDayCount
        )

        let score = calculateLoadComponentScore(
            current: previousLoad.value,
            baseline: baselineLoad?.value
        )

        return TrainingComponentScore(
            score: score,
            currentValue: previousLoad.value,
            baselineValue: baselineLoad?.value,
            unit: "kcal",
            minScore: -10,
            maxScore: 5,
            timestamp: previousLoad.date
        )
    }

    /// Calculates training readiness score based on previous day load compared to baseline.
    ///
    /// Lower previous day loads indicate better recovery and readiness for training.
    /// Higher loads suggest residual fatigue and need for recovery.
    ///
    /// - Parameters:
    ///   - current: Previous day's active energy burned in kcal
    ///   - baseline: Average daily active energy (7-day baseline) in kcal
    /// - Returns: Score from -10 to +5 based on recovery status
    private func calculateLoadComponentScore(current: Double, baseline: Double?) -> Int {
        // A baseline at or below zero would make the ratio meaningless or infinite.
        guard let baseline = baseline, baseline > 0 else {
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
