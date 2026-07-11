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

    // MARK: - Lifecycle

    public init(
        averageHeartRate: Double,
        heartRate: Double,
        activeEnergy: Double,
        heartRateSampleDate: Date? = nil
    ) {
        self.averageHeartRate = averageHeartRate
        self.heartRate = heartRate
        self.activeEnergy = activeEnergy
        self.heartRateSampleDate = heartRateSampleDate
    }

}
