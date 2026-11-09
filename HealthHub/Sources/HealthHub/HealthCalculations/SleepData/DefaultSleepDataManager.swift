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
        in windows: [ClosedRange<Date>],
        takingFirst count: Int
    ) async throws -> HealthKitData? {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return nil
        }

        // One query spanning every night, then grouped in memory. Seven nights
        // used to mean seven round trips to HealthKit for a single baseline.
        let allIntervals = try await asleepIntervals(in: start...end)

        let nightlyValues: [Double] = windows.compactMap { window in
            let hours = asleepHours(of: allIntervals, overlapping: window)

            return hours > 0 ? hours : nil
        }

        // Newest first, so this keeps the most recent nights that have data and
        // treats the rest of the pool as a reserve for gaps.
        let used = Array(nightlyValues.prefix(max(count, 1)))

        guard !used.isEmpty else { return nil }

        let average = used.reduce(0, +) / Double(used.count)

        return HealthKitData(date: windows.first?.upperBound ?? Date(), value: average)
    }

    public func nightSessions(
        in window: ClosedRange<Date>,
        calendar: Calendar
    ) async throws -> [Date: SleepSession] {
        let intervals = try await asleepIntervals(in: window)
        let sessions = SleepSessionBuilder.sessions(from: intervals)

        // Same rule the resolver uses for today: the longest qualifying session of
        // a day is its night, so a nap never stands in for one.
        return sessions.reduce(into: [Date: SleepSession]()) { result, session in
            guard session.asleepDuration >= SleepSessionBuilder.defaultMinimumNightDuration else {
                return
            }

            let day = calendar.startOfDay(for: session.end)

            if let existing = result[day], existing.asleepDuration >= session.asleepDuration {
                return
            }

            result[day] = session
        }
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

    /// Hours of sleep falling inside a window.
    ///
    /// Clips each interval to the window rather than keeping or dropping it by its
    /// start. Dropping a straddling interval wholesale under-reported every night
    /// of an early sleeper's baseline — a 19:30 bedtime lost its first 30 minutes
    /// against a 20:00 window — while the measured night was never clipped, so the
    /// comparison showed a surplus that did not exist.
    ///
    /// - Parameters:
    ///   - intervals: Raw asleep intervals spanning the whole range
    ///   - window: The night to measure
    /// - Returns: Hours asleep within the window
    private func asleepHours(
        of intervals: [SleepSessionBuilder.Interval],
        overlapping window: ClosedRange<Date>
    ) -> Double {
        let clipped = intervals.compactMap { interval -> SleepSessionBuilder.Interval? in
            let start = max(interval.start, window.lowerBound)
            let end = min(interval.end, window.upperBound)

            guard end > start else { return nil }

            return SleepSessionBuilder.Interval(start: start, end: end)
        }

        return totalAsleepHours(in: clipped)
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
