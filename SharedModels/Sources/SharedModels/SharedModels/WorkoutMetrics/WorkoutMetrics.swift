//
//  WorkoutMetrics.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

/// Represents key metrics during a workout session.
public struct WorkoutMetrics: Equatable, Sendable, Codable {
    
    // MARK: - Properties
    
    /// The average heart rate measured throughout the workout session, in beats per minute.
    public var averageHeartRate: Double
    
    /// The current heart rate at a specific moment during the workout, in beats per minute.
    public var heartRate: Double
    
    /// The amount of active energy burned during the workout session, measured in kilocalories.
    public var activeEnergy: Double

    /// Timestamp of the most recent REAL heart-rate sample (IOS-00100-A).
    ///
    /// iPhone-standalone only — read from `HKStatistics.mostRecentQuantityDateInterval()`.
    /// The builder's `mostRecentQuantity()` keeps returning the last value forever
    /// after a BLE strap drops out of range, so `heartRate` alone cannot distinguish
    /// a live reading from a stale repeat; only a moved timestamp proves freshness.
    /// `nil` on the Watch/mirroring path (and in decoded legacy payloads — optional
    /// keeps Codable backward-compatible), where consumers keep legacy behavior.
    public var heartRateSampleDate: Date?

    // MARK: - Distance Activities

    // Populated only for distance-based activities (cycling). Optional keeps the
    // Codable payload backward-compatible across Watch↔iPhone version skew —
    // same rule as `heartRateSampleDate`. SI units throughout (meters, m/s);
    // conversion to km / km/h happens at the formatting layer.

    /// Total distance covered so far, in meters.
    public var distance: Double?

    /// Most recent instantaneous speed, in meters per second.
    public var currentSpeed: Double?

    /// Average speed across the whole session, in meters per second.
    public var averageSpeed: Double?

    /// Maximum instantaneous speed recorded this session, in meters per second.
    public var maxSpeed: Double?

    /// Rolling average speed over the last 5 km, in meters per second.
    public var recentAverageSpeed: Double?

    /// Average speed over the last completed kilometer, in meters per second.
    public var lastKilometerSpeed: Double?

    // MARK: - Lifecycle

    public init(
        averageHeartRate: Double,
        heartRate: Double,
        activeEnergy: Double,
        heartRateSampleDate: Date? = nil,
        distance: Double? = nil,
        currentSpeed: Double? = nil,
        averageSpeed: Double? = nil,
        maxSpeed: Double? = nil,
        recentAverageSpeed: Double? = nil,
        lastKilometerSpeed: Double? = nil
    ) {
        self.averageHeartRate = averageHeartRate
        self.heartRate = heartRate
        self.activeEnergy = activeEnergy
        self.heartRateSampleDate = heartRateSampleDate
        self.distance = distance
        self.currentSpeed = currentSpeed
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.recentAverageSpeed = recentAverageSpeed
        self.lastKilometerSpeed = lastKilometerSpeed
    }

}
