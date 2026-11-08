//
//  TrainingReadinessClient+Mock.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 09/11/2025.
//

import SharedModels
import Foundation

public extension TrainingReadinessClient {

    static let mock = Self(
        calculate: {
            .ready(
                TrainingReadinessResult(
                    overallScore: 75,
                    components: TrainingReadinessComponents(
                        restingHeartRate: TrainingComponentScore(
                            score: 5,
                            currentValue: 56.0,
                            baselineValue: 58.5,
                            unit: HealthMetricType.rhr.unit,
                            minScore: HealthMetricType.rhr.minScore,
                            maxScore: HealthMetricType.rhr.maxScore
                        ),
                        heartRateVariability: TrainingComponentScore(
                            score: 12,
                            currentValue: 95.0,
                            baselineValue: 85.0,
                            unit: HealthMetricType.hrv.unit,
                            minScore: HealthMetricType.hrv.minScore,
                            maxScore: HealthMetricType.hrv.maxScore
                        ),
                        sleepQuality: TrainingComponentScore(
                            score: 10,
                            currentValue: 7.5,
                            baselineValue: 7.0,
                            unit: HealthMetricType.sleep.unit,
                            minScore: HealthMetricType.sleep.minScore,
                            maxScore: HealthMetricType.sleep.maxScore
                        ),
                        previousDayLoad: TrainingComponentScore(
                            score: -2,
                            currentValue: 750.0,
                            baselineValue: 650.0,
                            unit: HealthMetricType.activity.unit,
                            minScore: HealthMetricType.activity.minScore,
                            maxScore: HealthMetricType.activity.maxScore
                        )
                    ),
                    calculatedAt: Date(),
                    isReliable: true
                )
            )
        },
        history: { days in
            []
        }
    )

    /// Mock with realistic "Morning" scenario (Sleep & Activity synced, RHR & HRV pending)
    static let partialMock = Self(
        calculate: {
            .ready(
                TrainingReadinessResult(
                    overallScore: 60,
                    components: TrainingReadinessComponents(
                        restingHeartRate: nil,
                        heartRateVariability: nil,
                        sleepQuality: TrainingComponentScore(
                            score: 10,
                            currentValue: 7.5,
                            baselineValue: 7.0,
                            unit: HealthMetricType.sleep.unit,
                            minScore: HealthMetricType.sleep.minScore,
                            maxScore: HealthMetricType.sleep.maxScore
                        ),
                        previousDayLoad: TrainingComponentScore(
                            score: 5,
                            currentValue: 550.0,
                            baselineValue: 400.0,
                            unit: HealthMetricType.activity.unit,
                            minScore: HealthMetricType.activity.minScore,
                            maxScore: HealthMetricType.activity.maxScore
                        )
                    ),
                    calculatedAt: Date(),
                    isReliable: true
                )
            )
        },
        history: { _ in [] }
    )

    /// Mock for the morning state, before the night has been recorded.
    static let awaitingSleepMock = Self(
        calculate: { .awaitingSleepData(expectedBy: nil) },
        history: { _ in [] }
    )

}
