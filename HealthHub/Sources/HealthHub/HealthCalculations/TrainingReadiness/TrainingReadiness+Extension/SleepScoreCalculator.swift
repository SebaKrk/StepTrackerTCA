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
    /// Evaluates the night's sleep duration against optimal ranges and recent averages
    /// to determine recovery quality. Adequate sleep is critical for training readiness.
    ///
    /// Takes the duration straight from the resolved session when the day is sleep
    /// anchored — it has already been deduplicated and merged — and falls back to
    /// reading the clock window only when no session was recorded.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: `TrainingComponentScore` with sleep contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// - 7-9 hours of sleep: +10 points (optimal)
    /// - 6-7 or 9-10 hours: +5 points (acceptable)
    /// - Less than 6 or more than 10 hours: -10 points (suboptimal)
    /// - Additional points based on comparison to personal baseline
    func calculateSleepScore(for day: ReadinessDay) async throws -> TrainingComponentScore? {
        guard let currentHours = try await sleepHours(for: day) else {
            return nil
        }

        let baselineWindows = try await baselineNightWindows(for: day)
        let baselineSleep = try await sleepDataManager.getAverageSleepHours(
            in: baselineWindows,
            takingFirst: baselineDayCount
        )

        let score = calculateSleepComponentScore(
            current: currentHours,
            baseline: baselineSleep?.value
        )

        return TrainingComponentScore(
            score: score,
            currentValue: currentHours,
            baselineValue: baselineSleep?.value,
            // The only readiness unit that differs between languages (bpm/ms/kcal
            // are universal) — resolved against the app bundle at display time.
            unit: String(localized: "hours"),
            minScore: -15,
            maxScore: 15,
            timestamp: day.wakeTime
        )
    }

    /// Hours slept on the given day, from the session when there is one.
    private func sleepHours(for day: ReadinessDay) async throws -> Double? {
        if let session = day.sleepSession {
            return session.asleepHours > 0 ? session.asleepHours : nil
        }

        let measured = try await sleepDataManager.getAverageSleepHours(in: [day.nightWindow], takingFirst: 1)

        return measured?.value
    }

    /// Calculates score based on sleep duration and comparison to baseline.
    ///
    /// - Parameters:
    ///   - current: The night's sleep duration in hours
    ///   - baseline: Average sleep duration in hours (7-night baseline)
    /// - Returns: Score from -15 to +15 based on sleep quality
    private func calculateSleepComponentScore(current: Double, baseline: Double?) -> Int {
        var score = 0
        switch current {
        case 7.0...9.0:
            score += 10
        case 6.0..<7.0, 9.0...10.0:
            score += 5
        default:
            score -= 10
        }

        // Additional score based on baseline comparison
        if let baseline = baseline {
            let difference = current - baseline

            switch difference {
            case let diff where diff > 1.0:
                score += 5
            case let diff where diff < -1.5:
                score -= 5
            default:
                score += 0
            }
        }
        return score
    }
}
