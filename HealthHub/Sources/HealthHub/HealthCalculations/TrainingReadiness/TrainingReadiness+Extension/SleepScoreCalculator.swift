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

    /// Lowest long-term nightly average that still supports recovery.
    ///
    /// Below this the shortfall stops being a preference and starts being a debt.
    /// It never costs points — it only lets the app say so.
    static let minimumHealthySleepHours = 6.0

    /// Calculates training readiness score from how the night compares with the
    /// user's own baseline.
    ///
    /// What the night actually was — measured, nothing recorded, no sleep at all,
    /// or a recording that stopped early — is decided by `NightMeasurementResolver`.
    /// This function only turns hours into points.
    ///
    /// - Parameter day: The readiness day being calculated
    /// - Returns: `TrainingComponentScore` with sleep contribution, or `nil` if data unavailable
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Scoring Logic
    /// Entirely relative to the user's own baseline, in hours:
    /// - more than +1.0 against baseline: +15 points
    /// - +0.5 to +1.0: +10 points
    /// - within half an hour either way: 0 points — this is the norm
    /// - -1.5 to -0.5: -10 points
    /// - more than -1.5: -15 points
    func calculateSleepScore(
        for day: ReadinessDay,
        baselineWindows: [ClosedRange<Date>],
        includesLongTermTrends: Bool = true
    ) async throws -> TrainingComponentScore? {
        let measurement = try await nightMeasurementResolver.resolve(for: day)

        let currentHours: Double

        switch measurement {
        case let .measured(hours):
            currentHours = hours

        case .noSleep:
            // A measurement of zero, not an absence of one.
            currentHours = 0

        case .notWorn, .truncated:
            // Nothing to compare: either nothing was recorded, or what was
            // recorded stopped before the night did.
            return nil
        }

        let baselineSleep = try await sleepDataManager.getAverageSleepHours(
            in: baselineWindows,
            takingFirst: baselineDayCount
        )

        let score = calculateSleepComponentScore(
            current: currentHours,
            baseline: baselineSleep?.value
        )

        // Separate from the baseline on purpose: the baseline says what is normal
        // for this user, and a purely differential score therefore cannot notice
        // that the norm itself is too low. This window can.
        //
        // Skipped during a rebuild: only the current day displays it, no column
        // stores it, and asking for it there reads sixty nights per rebuilt day
        // to discard every answer.
        let longTermSleep = includesLongTermTrends
            ? try await sleepDataManager.getAverageSleepHours(
                in: TrainingReadinessTimeWindows.previousNights(
                    count: longTermSleepNightCount,
                    before: day,
                    calendar: calendar
                ),
                takingFirst: longTermSleepNightCount
            )
            : nil

        return TrainingComponentScore(
            score: score,
            currentValue: currentHours,
            baselineValue: baselineSleep?.value,
            // The only readiness unit that differs between languages (bpm/ms/kcal
            // are universal) — resolved against the app bundle at display time.
            unit: String(localized: "hours"),
            minScore: -15,
            maxScore: 15,
            timestamp: day.wakeTime,
            longTermValue: longTermSleep?.value,
            longTermMinimum: Self.minimumHealthySleepHours
        )
    }

    /// Calculates score from how the night compares with the user's own baseline.
    ///
    /// Purely differential, like resting heart rate and HRV. It used to add points
    /// for an absolute 7-9 hours regardless of the baseline, which broke the one
    /// promise the whole feature makes — that it compares you against yourself.
    /// Someone who always sleeps five hours was scored as badly recovered on a
    /// night that matched their own norm exactly, and a zero no longer meant
    /// "on your baseline" for this component alone.
    ///
    /// The cost is deliberate: chronic short sleep no longer shows up here. That
    /// is a fact about the user's habits, not about today's recovery, and it
    /// belongs wherever sleep itself is reported rather than in a readiness score.
    ///
    /// - Parameters:
    ///   - current: The night's sleep duration in hours
    ///   - baseline: Average sleep duration in hours
    /// - Returns: Score from -15 to +15 based on deviation from the baseline
    private func calculateSleepComponentScore(current: Double, baseline: Double?) -> Int {
        guard let baseline, baseline > 0 else { return 0 }

        let difference = current - baseline

        switch difference {
        case let diff where diff > 1.0:
            return 15
        case let diff where diff > 0.5:
            return 10
        case let diff where diff < -1.5:
            return -15
        case let diff where diff < -0.5:
            return -10
        default:
            return 0
        }
    }
}
