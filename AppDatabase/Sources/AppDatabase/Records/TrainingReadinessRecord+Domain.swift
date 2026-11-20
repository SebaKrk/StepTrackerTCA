//
//  TrainingReadinessRecord+Domain.swift
//  AppDatabase
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation
import SharedModels

// MARK: - Domain Mapping

public extension TrainingReadinessRecord {

    /// Builds a record from a calculated result.
    ///
    /// - Parameters:
    ///   - result: The calculated readiness result
    ///   - day: The day it was calculated for
    ///   - algorithmVersion: Version of the rules that produced it
    init(result: TrainingReadinessResult, day: ReadinessDay, algorithmVersion: Int) {
        let components = result.components

        self.init(
            id: ReadinessDayKey.key(for: day.dayStart),
            overallScore: result.overallScore,
            algorithmVersion: algorithmVersion,
            isReliable: result.isReliable,
            anchor: day.sleepSession == nil ? "clock" : "sleep",
            wakeTime: day.wakeTime,
            restingHeartRateScore: components.restingHeartRate?.score,
            restingHeartRateValue: components.restingHeartRate?.currentValue,
            restingHeartRateBaseline: components.restingHeartRate?.baselineValue,
            hrvScore: components.heartRateVariability?.score,
            hrvValue: components.heartRateVariability?.currentValue,
            hrvBaseline: components.heartRateVariability?.baselineValue,
            sleepScore: components.sleepQuality?.score,
            sleepValue: components.sleepQuality?.currentValue,
            sleepBaseline: components.sleepQuality?.baselineValue,
            loadScore: components.previousDayLoad?.score,
            loadValue: components.previousDayLoad?.currentValue,
            loadBaseline: components.previousDayLoad?.baselineValue,
            calculatedAt: result.calculatedAt
        )
    }

    /// Rebuilds the domain result so history reuses the same presentation logic
    /// as a freshly calculated day.
    ///
    /// `calculatedAt` carries the readiness day rather than the write timestamp:
    /// charts plot results by that property, and a day has to land on the day it
    /// describes, not on the moment the row happened to be written. A key that
    /// cannot be parsed falls back to `wakeTime`, which is on the same day.
    func toDomain() -> TrainingReadinessResult {
        TrainingReadinessResult(
            overallScore: overallScore,
            components: TrainingReadinessComponents(
                restingHeartRate: componentScore(
                    for: .rhr,
                    score: restingHeartRateScore,
                    value: restingHeartRateValue,
                    baseline: restingHeartRateBaseline
                ),
                heartRateVariability: componentScore(
                    for: .hrv,
                    score: hrvScore,
                    value: hrvValue,
                    baseline: hrvBaseline
                ),
                sleepQuality: componentScore(
                    for: .sleep,
                    score: sleepScore,
                    value: sleepValue,
                    baseline: sleepBaseline
                ),
                previousDayLoad: componentScore(
                    for: .activity,
                    score: loadScore,
                    value: loadValue,
                    baseline: loadBaseline
                )
            ),
            calculatedAt: ReadinessDayKey.dayStart(from: id) ?? wakeTime,
            isReliable: isReliable
        )
    }

    /// Rebuilds one component, or `nil` when it was missing that day.
    private func componentScore(
        for metric: HealthMetricType,
        score: Int?,
        value: Double?,
        baseline: Double?
    ) -> TrainingComponentScore? {
        guard let score, let value else { return nil }

        return TrainingComponentScore(
            score: score,
            currentValue: value,
            baselineValue: baseline,
            unit: metric.unit,
            minScore: metric.minScore,
            maxScore: metric.maxScore,
            timestamp: wakeTime
        )
    }
}
