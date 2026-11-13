//
//  HealthStoreSampleSource.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

import ComposableArchitecture
@preconcurrency import HealthKit
import SharedModels

/// Reads samples straight from HealthKit.
///
/// The default source behind the personal and sleep managers, and the one a
/// prefetch primes itself from.
public struct HealthStoreSampleSource: QuantitySampleSource, SleepSampleSource, @unchecked Sendable {

    // MARK: - Dependency

    @Dependency(\.authorizationManager) var manager

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Quantity API

    public func quantitySamples(
        of type: HKQuantityType,
        covering windows: [ClosedRange<Date>]
    ) async throws -> [HKQuantitySample] {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .forward)]
        )

        return try await descriptor.result(for: manager.healthStore)
    }

    public func dailyActiveEnergyTotals(
        covering windows: [ClosedRange<Date>]
    ) async throws -> [Date: Double] {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return [:]
        }

        let healthStore = manager.healthStore
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let collection: HKStatisticsCollection? = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<HKStatisticsCollection?, Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.activeEnergyBurned),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results)
                }
            }

            healthStore.execute(query)
        }

        guard let collection else { return [:] }

        var totals: [Date: Double] = [:]

        collection.enumerateStatistics(from: anchor, to: end) { statistics, _ in
            guard let sum = statistics.sumQuantity() else { return }

            totals[calendar.startOfDay(for: statistics.startDate)] =
                sum.doubleValue(for: .kilocalorie())
        }

        return totals
    }

    // MARK: - Sleep API

    public func asleepIntervals(
        in window: ClosedRange<Date>
    ) async throws -> [SleepSessionBuilder.Interval] {
        let predicate = HKQuery.predicateForSamples(
            withStart: window.lowerBound,
            end: window.upperBound,
            options: .strictStartDate
        )

        let samplePredicate = HKSamplePredicate.categorySample(
            type: HKCategoryType(.sleepAnalysis),
            predicate: predicate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKCategorySample.startDate, order: .forward)]
        )

        let samples = try await descriptor.result(for: manager.healthStore)

        return samples
            .filter(isAsleep)
            .map { SleepSessionBuilder.Interval(start: $0.startDate, end: $0.endDate) }
    }

    // MARK: - Private Methods

    /// Whether a sample represents actual sleep rather than time awake in bed.
    private func isAsleep(_ sample: HKCategorySample) -> Bool {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return false
        }

        switch value {
        case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified, .asleep:
            return true
        case .awake, .inBed:
            return false
        @unknown default:
            return false
        }
    }
}
