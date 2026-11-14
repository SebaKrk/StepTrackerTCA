//
//  PrefetchedHealthSamples.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 13/11/2026.
//

@preconcurrency import HealthKit
import SharedModels

/// Answers reads for a fixed range from one pass over HealthKit.
///
/// A history rebuild scores sixty days, and every one of them asks for the same
/// seven weeks of baseline behind it. Read live that is hundreds of queries over
/// ranges that almost entirely overlap; primed once it is four, and the rest is
/// filtering in memory.
///
/// Only the readings a rebuild asks for repeatedly are held. Anything else —
/// heart rate above all, which is read once per day and would dominate the
/// memory this saves — goes to the fallback, as does any range the prefetch does
/// not fully cover.
public struct PrefetchedHealthSamples: QuantitySampleSource, SleepSampleSource, @unchecked Sendable {

    // MARK: - Properties

    /// The range every held reading was read over.
    private let range: ClosedRange<Date>

    /// Held samples per quantity type, oldest first.
    private let samplesByType: [HKQuantityType: [HKQuantitySample]]

    /// Active energy summed per calendar day.
    private let energyTotals: [Date: Double]

    /// Asleep intervals across the whole range, oldest first.
    private let intervals: [SleepSessionBuilder.Interval]

    /// Where a read this prefetch cannot answer is sent.
    private let fallback: any QuantitySampleSource & SleepSampleSource

    // MARK: - Lifecycle

    /// Reads the range once and returns a source backed by what it found.
    ///
    /// Sequential on purpose: four queries are not worth the concurrency, and the
    /// hundreds this replaces were the cost worth removing.
    ///
    /// - Parameters:
    ///   - range: The span the caller will read inside of
    ///   - source: Where the prefetch reads from, and where it falls back to
    /// - Returns: A source answering from memory within `range`
    /// - Throws: HealthKit errors if data access fails
    public static func covering(
        _ range: ClosedRange<Date>,
        reading source: any QuantitySampleSource & SleepSampleSource = HealthStoreSampleSource()
    ) async throws -> PrefetchedHealthSamples {
        let restingHeartRateType = HKQuantityType(.restingHeartRate)
        let variabilityType = HKQuantityType(.heartRateVariabilitySDNN)

        let restingHeartRate = try await source.quantitySamples(
            of: restingHeartRateType,
            covering: [range]
        )
        let variability = try await source.quantitySamples(
            of: variabilityType,
            covering: [range]
        )
        let energyTotals = try await source.dailyActiveEnergyTotals(covering: [range])
        let intervals = try await source.asleepIntervals(in: range)

        return PrefetchedHealthSamples(
            range: range,
            samplesByType: [
                restingHeartRateType: restingHeartRate,
                variabilityType: variability
            ],
            energyTotals: energyTotals,
            intervals: intervals,
            fallback: source
        )
    }

    // MARK: - Quantity API

    public func quantitySamples(
        of type: HKQuantityType,
        covering windows: [ClosedRange<Date>]
    ) async throws -> [HKQuantitySample] {
        guard let span = span(of: windows) else { return [] }

        guard let samples = samplesByType[type], covers(span) else {
            return try await fallback.quantitySamples(of: type, covering: windows)
        }

        return samples.filter { span.contains($0.startDate) }
    }

    public func dailyActiveEnergyTotals(
        covering windows: [ClosedRange<Date>]
    ) async throws -> [Date: Double] {
        guard let span = span(of: windows) else { return [:] }

        guard covers(span) else {
            return try await fallback.dailyActiveEnergyTotals(covering: windows)
        }

        // The live read anchors its buckets at the start of the first day, so the
        // keys it returns run from there rather than from the window itself.
        let firstDay = Calendar.current.startOfDay(for: span.lowerBound)

        return energyTotals.filter { (firstDay...span.upperBound).contains($0.key) }
    }

    // MARK: - Sleep API

    public func asleepIntervals(
        in window: ClosedRange<Date>
    ) async throws -> [SleepSessionBuilder.Interval] {
        guard covers(window) else {
            return try await fallback.asleepIntervals(in: window)
        }

        // Selected by start date, matching the predicate the live read uses — an
        // interval that began before the window is absent there too.
        return intervals.filter { window.contains($0.start) }
    }

    // MARK: - Private Methods

    /// The overall span a set of windows reaches across.
    private func span(of windows: [ClosedRange<Date>]) -> ClosedRange<Date>? {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max(),
              start <= end else {
            return nil
        }

        return start...end
    }

    /// Whether everything a span asks for was read at prefetch time.
    private func covers(_ span: ClosedRange<Date>) -> Bool {
        range.lowerBound <= span.lowerBound && span.upperBound <= range.upperBound
    }
}
