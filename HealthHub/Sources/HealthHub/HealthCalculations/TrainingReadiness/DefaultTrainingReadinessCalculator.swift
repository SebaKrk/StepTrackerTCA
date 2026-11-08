//
//  DefaultTrainingReadinessCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@preconcurrency
public final class DefaultTrainingReadinessCalculator: TrainingReadinessCalculator, @unchecked Sendable {

    // MARK: - Dependency

    @Dependency(\.personalDataManager) var personalDataManager
    @Dependency(\.sleepDataManager) var sleepDataManager
    @Dependency(\.date) var date

    // MARK: - Properties

    /// How many preceding days each component compares itself against.
    let baselineDayCount = 7

    /// Resolves which day is being scored, and whether it can be scored yet.
    ///
    /// Built per call so its own dependencies resolve in the caller's context.
    private var dayResolver: ReadinessDayResolver {
        ReadinessDayResolver()
    }

    // MARK: - Lifecycle

    public init() {}

    // MARK: - API

    public func calculateTrainingReadiness() async throws -> TrainingReadinessResult {
        guard let day = try await dayResolver.resolve() else {
            throw ReadinessCalculationError.awaitingSleepData(
                expectedBy: dayResolver.expectedAvailability()
            )
        }

        return try await calculateTrainingReadiness(for: day)
    }

    /// Calculates readiness for an already resolved day.
    ///
    /// Separated so the day can be resolved once and reused — and so the scoring
    /// itself takes no reading of the current time.
    ///
    /// - Parameter day: The day to score
    /// - Returns: The readiness result for that day
    /// - Throws: HealthKit errors if data access fails
    func calculateTrainingReadiness(for day: ReadinessDay) async throws -> TrainingReadinessResult {
        let restingHeartRateComponent = try await calculateRestingHeartRateScore(for: day)
        let hrvComponent = try await calculateHRVScore(for: day)
        let sleepComponent = try await calculateSleepScore(for: day)
        let activityLoadComponent = try await calculateActivityLoadScore(for: day)

        let components = TrainingReadinessComponents(
            restingHeartRate: restingHeartRateComponent,
            heartRateVariability: hrvComponent,
            sleepQuality: sleepComponent,
            previousDayLoad: activityLoadComponent
        )

        let overallScore = calculateOverallScore(from: components)
        let isReliable = checkReliability(components: components)

        return TrainingReadinessResult(
            overallScore: overallScore,
            components: components,
            calculatedAt: date.now,
            isReliable: isReliable
        )
    }

    public func getTrainingReadinessHistory(days: Int) async throws -> [TrainingReadinessResult] {
        return []
    }

    // MARK: - Private Methods

    /// Combines component scores into a 0-100 readiness score.
    ///
    /// Normalises against the components that are actually present, so a day
    /// missing HRV is not scored lower than the same day with it. A day where
    /// every component sits on its own baseline lands on the neutral score.
    private func calculateOverallScore(from components: TrainingReadinessComponents) -> Int {
        let available = components.available

        guard !available.isEmpty else { return ReadinessLevel.neutralScore }

        let points = available.reduce(0) { $0 + $1.score }

        // Positive and negative headroom differ per component, so the direction
        // of the deviation decides which pool it is measured against.
        let headroom = points >= 0
            ? available.reduce(0) { $0 + $1.maxScore }
            : available.reduce(0) { $0 + abs($1.minScore) }

        guard headroom > 0 else { return ReadinessLevel.neutralScore }

        let span = Double(ReadinessLevel.neutralScore)
        let offset = (span * Double(points) / Double(headroom)).rounded()

        return max(0, min(100, ReadinessLevel.neutralScore + Int(offset)))
    }

    private func checkReliability(components: TrainingReadinessComponents) -> Bool {
        components.available.count >= TrainingReadinessResult.minimumReliableComponents
    }
}
