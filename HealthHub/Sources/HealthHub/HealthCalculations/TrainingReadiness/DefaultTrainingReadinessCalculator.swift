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

    private func calculateOverallScore(from components: TrainingReadinessComponents) -> Int {
        var totalScore = 50
        var componentCount = 0

        if let rhr = components.restingHeartRate {
            totalScore += rhr.score
            componentCount += 1
        }

        if let hrv = components.heartRateVariability {
            totalScore += hrv.score
            componentCount += 1
        }

        if let sleep = components.sleepQuality {
            totalScore += sleep.score
            componentCount += 1
        }

        if let load = components.previousDayLoad {
            totalScore += load.score
            componentCount += 1
        }

        return max(0, min(100, totalScore))
    }

    private func checkReliability(components: TrainingReadinessComponents) -> Bool {
        let availableComponents = [
            components.restingHeartRate,
            components.heartRateVariability,
            components.sleepQuality,
            components.previousDayLoad
        ].compactMap { $0 }.count

        return availableComponents >= 2 || components.restingHeartRate != nil
    }
}
