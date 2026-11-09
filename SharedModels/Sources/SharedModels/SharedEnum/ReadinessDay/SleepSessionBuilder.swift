//
//  SleepSessionBuilder.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 08/11/2026.
//

import Foundation

/// Rebuilds continuous sleep sessions out of raw HealthKit sleep intervals.
///
/// Takes plain date intervals rather than `HKCategorySample` so the grouping
/// logic stays testable without HealthKit, and therefore without a simulator.
public enum SleepSessionBuilder {

    /// A raw asleep interval, as stored by HealthKit.
    public struct Interval: Sendable, Equatable {

        /// When the interval begins.
        public let start: Date

        /// When the interval ends.
        public let end: Date

        /// Creates a raw interval.
        ///
        /// - Parameters:
        ///   - start: Interval start
        ///   - end: Interval end
        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }

    /// Gap below which two intervals still count as the same night.
    ///
    /// Mid-night awakenings are normal and must not split one night into two
    /// sessions; a longer gap means a separate sleep, such as an afternoon nap.
    public static let defaultMaxGap: TimeInterval = 60 * 60

    /// Shortest session that still counts as a night.
    ///
    /// Below this it is a nap, or an evening HealthKit has not finished writing —
    /// either way not something a day should be scored against.
    public static let defaultMinimumNightDuration: TimeInterval = 3 * 60 * 60

    /// Groups intervals into sessions, newest last.
    ///
    /// - Parameters:
    ///   - intervals: Raw asleep intervals, in any order
    ///   - maxGap: Largest gap that still belongs to the same session
    /// - Returns: Sessions ordered chronologically, empty when no input
    public static func sessions(
        from intervals: [Interval],
        maxGap: TimeInterval = defaultMaxGap
    ) -> [SleepSession] {
        let merged = mergedOverlaps(in: intervals)
        guard !merged.isEmpty else { return [] }

        var sessions: [SleepSession] = []
        var group: [Interval] = [merged[0]]

        for interval in merged.dropFirst() {
            let previousEnd = group[group.count - 1].end

            if interval.start.timeIntervalSince(previousEnd) <= maxGap {
                group.append(interval)
            } else {
                sessions.append(session(from: group))
                group = [interval]
            }
        }
        sessions.append(session(from: group))

        return sessions
    }

    /// Returns the most recent session that already ended before a cutoff.
    ///
    /// A session still in progress is excluded on purpose — readiness must not
    /// score half a night.
    ///
    /// - Parameters:
    ///   - intervals: Raw asleep intervals, in any order
    ///   - cutoff: Moment the session has to have ended before
    ///   - maxGap: Largest gap that still belongs to the same session
    /// - Returns: The latest closed session, or `nil` when there is none
    public static func nightSession(
        from intervals: [Interval],
        endedBefore cutoff: Date,
        minimumDuration: TimeInterval = defaultMinimumNightDuration,
        maxGap: TimeInterval = defaultMaxGap
    ) -> SleepSession? {
        sessions(from: intervals, maxGap: maxGap)
            .filter { $0.end <= cutoff && $0.asleepDuration >= minimumDuration }
            .max { $0.asleepDuration < $1.asleepDuration }
    }

    // MARK: - Private Helpers

    /// Deduplicates and merges overlapping intervals, sorted by start.
    private static func mergedOverlaps(in intervals: [Interval]) -> [Interval] {
        let unique = Set(intervals.map { IntervalKey(start: $0.start, end: $0.end) })
        let sorted = unique
            .map { Interval(start: $0.start, end: $0.end) }
            .sorted { $0.start < $1.start }

        var merged: [Interval] = []

        for interval in sorted {
            guard let last = merged.last, interval.start <= last.end else {
                merged.append(interval)
                continue
            }
            merged[merged.count - 1] = Interval(
                start: last.start,
                end: max(last.end, interval.end)
            )
        }

        return merged
    }

    /// Builds a session from already merged, non-overlapping intervals.
    private static func session(from group: [Interval]) -> SleepSession {
        let asleep = group.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }

        return SleepSession(
            start: group[0].start,
            end: group[group.count - 1].end,
            asleepDuration: asleep
        )
    }

    /// Hashable key used to drop byte-identical duplicates from device sync.
    private struct IntervalKey: Hashable {

        /// Interval start.
        let start: Date

        /// Interval end.
        let end: Date
    }
}
