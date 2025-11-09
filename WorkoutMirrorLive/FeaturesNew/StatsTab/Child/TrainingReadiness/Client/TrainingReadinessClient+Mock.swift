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
            TrainingReadinessResult(
                overallScore: 75,
                components: TrainingReadinessComponents(
                    restingHeartRate: TrainingComponentScore(
                        score: 5,
                        currentValue: 56.0,
                        baselineValue: 58.5,
                        unit: "bpm",
                        minScore: -15,
                        maxScore: 15
                    ),
                    heartRateVariability: TrainingComponentScore(
                        score: 12,
                        currentValue: 95.0,
                        baselineValue: 85.0,
                        unit: "ms",
                        minScore: -15,
                        maxScore: 15
                    ),
                    sleepQuality: TrainingComponentScore(
                        score: 10,
                        currentValue: 7.5,
                        baselineValue: 7.0,
                        unit: "hours",
                        minScore: -10,
                        maxScore: 15
                    ),
                    previousDayLoad: TrainingComponentScore(
                        score: -2,
                        currentValue: 750.0,
                        baselineValue: 650.0,
                        unit: "kcal",
                        minScore: -10,
                        maxScore: 5
                    )
                ),
                calculatedAt: Date(),
                isReliable: true
            )
        },
        history: { days in
            []
        }
    )
}
