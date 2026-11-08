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
    @Dependency(\.readinessHistoryClient) var readinessHistoryClient
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

    public func calculateReadinessOutcome() async throws -> ReadinessOutcome {
        let resolver = dayResolver

        guard let day = try await resolver.resolve() else {
            return .awaitingSleepData(expectedBy: resolver.expectedAvailability())
        }

        let result = try await calculateTrainingReadiness(for: day)

        if result.healthKitAccessDenied {
            return .accessDenied
        }

        if result.hasInsufficientData {
            return .insufficientData
        }

        // Persisted here rather than in the feature, so the background observer
        // path records history too — it is what runs on most mornings. Only days
        // worth showing are stored; a partial read must not enter the trend.
        // A failed write must not cost the user today's score.
        do {
            try await readinessHistoryClient.save(result, day)
        } catch {
            #if DEBUG
            print("❌ Failed to persist readiness for \(day.dayStart): \(error.localizedDescription)")
            #endif
        }

        return .ready(result)
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
        // The four components share no state and each issues its own HealthKit
        // reads, so running them in sequence only added up their latencies.
        async let restingHeartRateComponent = calculateRestingHeartRateScore(for: day)
        async let hrvComponent = calculateHRVScore(for: day)
        async let sleepComponent = calculateSleepScore(for: day)
        async let activityLoadComponent = calculateActivityLoadScore(for: day)

        let components = try await TrainingReadinessComponents(
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
        try await readinessHistoryClient.history(days)
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
