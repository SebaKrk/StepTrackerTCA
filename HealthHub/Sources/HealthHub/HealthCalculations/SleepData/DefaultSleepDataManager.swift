//
//  DefaultSleepDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

@preconcurrency
public final class DefaultSleepDataManager: SleepDataManager, @unchecked Sendable {

    // MARK: - Dependency

    @Dependency(\.authorizationManager) var manager

    // MARK: - Lifecycle

    public init() {}

    // MARK: - API

    public func getSleepIntervals(
        in window: ClosedRange<Date>
    ) async throws -> [SleepSessionBuilder.Interval] {
        try await asleepIntervals(in: window)
    }

    public func getAverageSleepHours(
        in windows: [ClosedRange<Date>]
    ) async throws -> HealthKitData? {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return nil
        }

        // One query spanning every night, then grouped in memory. Seven nights
        // used to mean seven round trips to HealthKit for a single baseline.
        let allIntervals = try await asleepIntervals(in: start...end)

        let nightlyValues: [Double] = windows.compactMap { window in
            let nightIntervals = allIntervals.filter { window.contains($0.start) }
            let hours = totalAsleepHours(in: nightIntervals)

            return hours > 0 ? hours : nil
        }

        guard !nightlyValues.isEmpty else { return nil }

        let average = nightlyValues.reduce(0, +) / Double(nightlyValues.count)

        return HealthKitData(date: windows.first?.upperBound ?? Date(), value: average)
    }

    // MARK: - Historical Data Per-Night Implementation

    public func getSleepHistory(nights: Int) async throws -> [HealthKitData?] {
        let calendar = Calendar.current
        var results: [HealthKitData?] = []

        for nightsAgo in 0..<nights {
            guard let targetDate = calendar.date(byAdding: .day, value: -nightsAgo, to: Date()),
                  let window = TrainingReadinessTimeWindows.fallbackNightWindow(
                      endingOn: calendar.startOfDay(for: targetDate),
                      calendar: calendar
                  ) else {
                results.append(nil)
                continue
            }

            let intervals = try await asleepIntervals(in: window)
            let hours = totalAsleepHours(in: intervals)

            results.append(
                hours > 0 ? HealthKitData(date: window.lowerBound, value: hours) : nil
            )
        }

        return results.reversed()
    }

    // MARK: - Private Methods

    /// Reads asleep intervals from HealthKit, dropping awake and in-bed periods.
    private func asleepIntervals(
        in window: ClosedRange<Date>
    ) async throws -> [SleepSessionBuilder.Interval] {
        let sleepType = HKCategoryType(.sleepAnalysis)

        let predicate = HKQuery.predicateForSamples(
            withStart: window.lowerBound,
            end: window.upperBound,
            options: .strictStartDate
        )

        let samplePredicate = HKSamplePredicate.categorySample(
            type: sleepType,
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

    /// Total time asleep across intervals, with duplicates and overlaps removed.
    ///
    /// HealthKit returns duplicated samples whenever two devices sync the same
    /// night, so the intervals have to be merged before they are summed.
    private func totalAsleepHours(in intervals: [SleepSessionBuilder.Interval]) -> Double {
        SleepSessionBuilder
            .sessions(from: intervals)
            .reduce(0.0) { $0 + $1.asleepDuration } / 3600.0
    }

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

// MARK: - Debug Extension

extension HKCategoryValueSleepAnalysis {
    var debugName: String {
        switch self {
        case .asleepCore: return "Core"
        case .asleepDeep: return "Deep"
        case .asleepREM: return "REM"
        case .asleepUnspecified: return "Unspecified"
        case .asleep: return "Asleep"
        case .awake: return "Awake"
        case .inBed: return "InBed"
        @unknown default: return "Unknown"
        }
    }
}
