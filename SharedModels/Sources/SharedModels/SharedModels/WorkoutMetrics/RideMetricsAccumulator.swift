//
//  RideMetricsAccumulator.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 06/08/2026.
//

import Foundation

/// Pure accumulator turning raw ride samples (GPS speed, cumulative HealthKit
/// distance) into the distance/speed fields of `WorkoutMetrics`.
///
/// Hardware-free by design: both workout engines (`iPhoneWorkoutSession` and the
/// Watch session manager) feed it and get identical math — rolling windows,
/// max/average — so the two workout paths can never drift apart. The owner is
/// responsible for thread safety (both engines guard it with their own lock).
///
/// Pause-aware: `setPaused(_:at:)` freezes intake and removes the paused
/// stretch from the rolling-window time axis, so "last km / last 5 km" resume
/// exactly where they left off. Average speed is pause-aware through the
/// builder's `elapsedTime` passed into `apply`.
public struct RideMetricsAccumulator: Sendable {

    // MARK: - Constants

    /// Rolling window of the "average last 5 km" metric, in meters.
    private static let longWindow: Double = 5_000

    /// Rolling window of the "pace last km" metric, in meters.
    private static let shortWindow: Double = 1_000

    /// A GPS speed sample older than this no longer represents "current" speed —
    /// fall back to the distance-delta estimate.
    private static let gpsSpeedFreshWindow: TimeInterval = 5

    /// A distance-delta speed estimate older than this means the rider is
    /// effectively stationary (or data stopped) — report no current speed.
    private static let deltaSpeedFreshWindow: TimeInterval = 15

    // MARK: - State

    private var totalDistance: Double = 0
    private var maxSpeed: Double = 0

    /// Most recent valid GPS speed (`CLLocation.speed >= 0`), wall-clock dated
    /// (freshness only — decays to an honest 0 while paused).
    private var gpsSpeed: (value: Double, date: Date)?

    /// Speed derived from consecutive distance samples — the only source on
    /// GPS-less rides (indoor trainer with a paired sensor).
    private var deltaSpeed: (value: Double, date: Date)?

    /// Previous distance sample on the ACTIVE time axis (delta-speed math).
    private var lastDistanceSample: (distance: Double, activeTime: TimeInterval)?

    /// Distance-time timeline for the rolling windows, on the ACTIVE time axis,
    /// trimmed to the span the longest window can reach back to.
    private var checkpoints: [(distance: Double, activeTime: TimeInterval)] = []

    // MARK: - Pause tracking

    /// Set while the session is paused — intake is frozen.
    private var pauseStartedAt: Date?

    /// Total time spent paused so far — subtracted from the wall clock to get
    /// the active time axis.
    private var totalPausedTime: TimeInterval = 0

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Input

    /// Mirrors the `HKWorkoutSession` pause state. While paused no samples are
    /// accepted and the paused stretch is excluded from rolling-window time.
    public mutating func setPaused(_ paused: Bool, at date: Date) {
        if paused {
            guard pauseStartedAt == nil else { return }
            pauseStartedAt = date
        } else {
            guard let pauseStart = pauseStartedAt else { return }
            totalPausedTime += max(0, date.timeIntervalSince(pauseStart))
            pauseStartedAt = nil
        }
    }

    /// Records a GPS speed sample. Negative values (CoreLocation's "invalid")
    /// and samples arriving while paused are ignored.
    public mutating func recordLocationSpeed(_ metersPerSecond: Double, at date: Date) {
        guard pauseStartedAt == nil, metersPerSecond >= 0 else { return }
        gpsSpeed = (metersPerSecond, date)
        maxSpeed = max(maxSpeed, metersPerSecond)
    }

    /// Records the builder's cumulative distance (meters). Non-monotonic
    /// samples (HealthKit re-delivery) and samples during a pause are ignored.
    public mutating func recordDistance(total: Double, at date: Date) {
        guard pauseStartedAt == nil, total >= totalDistance else { return }
        let activeNow = activeTime(at: date)
        if let last = lastDistanceSample, activeNow - last.activeTime > 0.5 {
            let speed = (total - last.distance) / (activeNow - last.activeTime)
            deltaSpeed = (speed, date)
            maxSpeed = max(maxSpeed, speed)
        }
        lastDistanceSample = (total, activeNow)
        totalDistance = total
        checkpoints.append((total, activeNow))
        trimCheckpoints()
    }

    // MARK: - Output

    /// Returns a copy of `metrics` with the ride fields filled from the
    /// accumulated samples. `elapsedTime` is the builder's pause-aware elapsed
    /// time; `date` is "now" for freshness/rolling-window math.
    public func apply(
        to metrics: WorkoutMetrics,
        elapsedTime: TimeInterval,
        at date: Date
    ) -> WorkoutMetrics {
        var updated = metrics
        updated.distance = totalDistance
        updated.currentSpeed = currentSpeed(at: date)
        updated.averageSpeed = elapsedTime > 0 ? totalDistance / elapsedTime : nil
        updated.maxSpeed = maxSpeed > 0 ? maxSpeed : nil
        updated.recentAverageSpeed = rollingSpeed(window: Self.longWindow, at: date)
        updated.lastKilometerSpeed = rollingSpeed(window: Self.shortWindow, at: date)
        return updated
    }

    // MARK: - Private

    /// Wall clock minus every paused stretch — the time axis all rolling-window
    /// math lives on. Frozen while a pause is in progress.
    private func activeTime(at date: Date) -> TimeInterval {
        let inProgressPause = pauseStartedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return date.timeIntervalSinceReferenceDate - totalPausedTime - inProgressPause
    }

    private func currentSpeed(at date: Date) -> Double? {
        if let gpsSpeed, date.timeIntervalSince(gpsSpeed.date) <= Self.gpsSpeedFreshWindow {
            return gpsSpeed.value
        }
        if let deltaSpeed, date.timeIntervalSince(deltaSpeed.date) <= Self.deltaSpeedFreshWindow {
            return deltaSpeed.value
        }
        // Stale sources with any past movement = stationary rider → honest zero.
        // No samples at all = data hasn't started → nil (UI shows placeholder).
        return (gpsSpeed ?? deltaSpeed) != nil ? 0 : nil
    }

    private func rollingSpeed(window: Double, at date: Date) -> Double? {
        guard totalDistance >= window else { return nil }
        let target = totalDistance - window
        guard let checkpoint = checkpoints.first(where: { $0.distance >= target }) else { return nil }
        let interval = activeTime(at: date) - checkpoint.activeTime
        guard interval > 0 else { return nil }
        return (totalDistance - checkpoint.distance) / interval
    }

    private mutating func trimCheckpoints() {
        // Keep a margin behind the long window so its lookup always lands on a
        // retained checkpoint.
        let floor = totalDistance - Self.longWindow - 100
        guard floor > 0 else { return }
        if let firstKept = checkpoints.firstIndex(where: { $0.distance >= floor }), firstKept > 0 {
            checkpoints.removeFirst(firstKept)
        }
    }
}
