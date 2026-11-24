//
//  PauseActivityDetector.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/11/2026.
//

import Foundation

/// Tells a real pause from one pressed by accident, by how the heart rate behaves after it.
///
/// A heart at rest keeps falling, zone after zone; one still working stops falling or climbs.
/// So the detector remembers the lowest zone reached since the pause and how long it has held.
public struct PauseActivityDetector: Equatable, Sendable {

    // MARK: - Rules

    /// A climb above the lowest zone counts once it has lasted this long; one high reading proves nothing.
    public static let risingSeconds: TimeInterval = 15

    /// Rest counts once it has lasted this long; one low reading must not withdraw a question.
    public static let restingSeconds: TimeInterval = 10

    /// Readings further apart than this say nothing about the time between them, so the clocks start again.
    public static let readingGapSeconds: TimeInterval = 20

    /// How long a zone must hold before it counts as work; recovery slows down as it nears rest.
    public static func holdingSeconds(for zone: HeartRateZone) -> TimeInterval {
        switch zone {
        case .resting, .recovery: 120
        case .fatBurning: 105
        case .aerobic, .threshold, .anaerobic: 60
        }
    }

    // MARK: - Properties

    /// `true` while a pause is being watched.
    public private(set) var isWatching = false

    /// The lowest zone seen since the pause began; `nil` until the first reading of the pause.
    public private(set) var lowestZone: HeartRateZone?

    /// When `lowestZone` was reached; the time it has held is counted from here.
    public private(set) var lowestSince: Date?

    /// When the heart rate last climbed above `lowestZone` and stayed there; `nil` while it is not above it.
    public private(set) var risenSince: Date?

    /// When the heart rate last reached rest and stayed there; `nil` while it is not at rest.
    public private(set) var restingSince: Date?

    /// A zone below the low seen in one reading only; a second one confirms it, a glitch cannot.
    public private(set) var unconfirmedLow: HeartRateZone?

    /// When the previous reading was taken; a long gap restarts the clocks.
    public private(set) var lastReadingAt: Date?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Watching

    /// Starts watching a pause.
    ///
    /// `zone` is the zone at the moment of the pause when a fresh reading says so; without one
    /// the first two readings of the pause set the yardstick.
    public mutating func begin(zone: HeartRateZone?, at date: Date) {
        self = PauseActivityDetector()
        isWatching = true
        guard let zone else { return }
        lowestZone = zone
        lowestSince = date
        lastReadingAt = date
    }

    /// Stops watching; readings are `undecided` until the next `begin`.
    public mutating func end() {
        self = PauseActivityDetector()
    }

    /// Takes one reading from the pause and says what the heart rate has shown so far.
    public mutating func observe(zone: HeartRateZone, at date: Date) -> PauseActivityVerdict {
        guard isWatching else { return .undecided }
        defer { lastReadingAt = date }

        if let lastReadingAt, date.timeIntervalSince(lastReadingAt) > Self.readingGapSeconds {
            lowestZone = nil
            unconfirmedLow = nil
            risenSince = nil
            restingSince = nil
        }
        guard let lowest = lowestZone, let lowestSince else {
            // Seeded from the higher of the first two readings, so a glitch cannot set the yardstick.
            if let first = unconfirmedLow {
                lowestZone = Self.higher(first, zone)
                lowestSince = date
                unconfirmedLow = nil
            } else {
                unconfirmedLow = zone
            }
            restingSince = zone == .resting ? (restingSince ?? date) : nil
            return .undecided
        }

        let change = Self.intensity(of: zone) - Self.intensity(of: lowest)
        if change < 0 {
            if let previous = unconfirmedLow {
                // Two readings in a row below the low: the fall is real, and the clock starts again.
                lowestZone = Self.higher(previous, zone)
                self.lowestSince = date
                unconfirmedLow = nil
            } else {
                // Not a new low yet, but the zone did not simply hold either: the hold clock starts again.
                unconfirmedLow = zone
                self.lowestSince = date
            }
        } else {
            unconfirmedLow = nil
        }

        if zone == .resting {
            risenSince = nil
            let since = restingSince ?? date
            restingSince = since
            return date.timeIntervalSince(since) >= Self.restingSeconds ? .resting : .undecided
        }
        restingSince = nil

        if change < 0 {
            risenSince = nil
            return .undecided
        }
        if change == 0 {
            risenSince = nil
            return date.timeIntervalSince(lowestSince) >= Self.holdingSeconds(for: zone) ? .stillTraining : .undecided
        }
        // After a real rest the next zone up is only standing or walking; work starts a zone higher.
        if lowest == .resting, change < 2 {
            risenSince = nil
            return .undecided
        }
        let since = risenSince ?? date
        risenSince = since
        return date.timeIntervalSince(since) >= Self.risingSeconds ? .stillTraining : .undecided
    }

    // MARK: - Private

    /// The more intense of two zones.
    private static func higher(_ first: HeartRateZone, _ second: HeartRateZone) -> HeartRateZone {
        intensity(of: first) >= intensity(of: second) ? first : second
    }

    /// Position of a zone from rest upwards; `HeartRateZone` declares its cases in that order.
    private static func intensity(of zone: HeartRateZone) -> Int {
        HeartRateZone.allCases.firstIndex(of: zone) ?? 0
    }
}
