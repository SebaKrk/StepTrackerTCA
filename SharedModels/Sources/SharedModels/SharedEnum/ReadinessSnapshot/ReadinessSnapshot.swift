//
//  ReadinessSnapshot.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

import Foundation

/// Wire format for sending a training readiness result to the paired Apple Watch.
///
/// Domain types (`TrainingReadinessResult` and friends) are deliberately not
/// `Codable`: this payload crosses a device boundary and has to stay stable
/// independently of how the domain model evolves.
public struct ReadinessSnapshot: Codable, Sendable, Equatable {

    /// Wire format of a single readiness component.
    ///
    /// Mirrors `TrainingComponentScore` field by field, including `minScore`
    /// and `maxScore` — without them the receiver cannot derive `status`,
    /// which is what drives component colouring.
    public struct Component: Codable, Sendable, Equatable {

        /// Component contribution to the overall score.
        public let score: Int

        /// Current measured value in the component's native unit.
        public let currentValue: Double

        /// Recent average used for comparison, or `nil` when history is too short.
        public let baselineValue: Double?

        /// Human-readable unit string, e.g. "bpm", "ms", "hours", "kcal".
        public let unit: String

        /// Lowest score this component can contribute.
        public let minScore: Int

        /// Highest score this component can contribute.
        public let maxScore: Int

        /// When the underlying measurement was taken.
        public let timestamp: Date?
    }

    /// Format version, so an older Watch build can reject a newer payload
    /// instead of decoding it partially.
    public static let currentSchemaVersion = 1

    /// Version of the format this payload was encoded with.
    public let schemaVersion: Int

    /// Overall readiness score from 0 to 100.
    public let overallScore: Int

    /// When the result was calculated on iPhone.
    public let calculatedAt: Date

    /// Whether the calculation was based on sufficient data.
    public let isReliable: Bool

    /// Resting heart rate component, or `nil` when unavailable.
    public let restingHeartRate: Component?

    /// Heart rate variability component, or `nil` when unavailable.
    public let heartRateVariability: Component?

    /// Sleep component, or `nil` when unavailable.
    public let sleepQuality: Component?

    /// Previous day activity load component, or `nil` when unavailable.
    public let previousDayLoad: Component?
}

// MARK: - Domain Mapping

public extension ReadinessSnapshot {

    /// Builds a snapshot from a calculated result.
    init(result: TrainingReadinessResult) {
        self.schemaVersion = Self.currentSchemaVersion
        self.overallScore = result.overallScore
        self.calculatedAt = result.calculatedAt
        self.isReliable = result.isReliable
        self.restingHeartRate = Component(result.components.restingHeartRate)
        self.heartRateVariability = Component(result.components.heartRateVariability)
        self.sleepQuality = Component(result.components.sleepQuality)
        self.previousDayLoad = Component(result.components.previousDayLoad)
    }

    /// Rebuilds the domain result so consumers can reuse `readinessLevel`,
    /// `status` and the rest of the existing presentation logic.
    var result: TrainingReadinessResult {
        TrainingReadinessResult(
            overallScore: overallScore,
            components: TrainingReadinessComponents(
                restingHeartRate: restingHeartRate?.componentScore,
                heartRateVariability: heartRateVariability?.componentScore,
                sleepQuality: sleepQuality?.componentScore,
                previousDayLoad: previousDayLoad?.componentScore
            ),
            calculatedAt: calculatedAt,
            isReliable: isReliable
        )
    }
}

fileprivate extension ReadinessSnapshot.Component {

    init?(_ score: TrainingComponentScore?) {
        guard let score else { return nil }
        self.init(
            score: score.score,
            currentValue: score.currentValue,
            baselineValue: score.baselineValue,
            unit: score.unit,
            minScore: score.minScore,
            maxScore: score.maxScore,
            timestamp: score.timestamp
        )
    }

    var componentScore: TrainingComponentScore {
        TrainingComponentScore(
            score: score,
            currentValue: currentValue,
            baselineValue: baselineValue,
            unit: unit,
            minScore: minScore,
            maxScore: maxScore,
            timestamp: timestamp
        )
    }
}
