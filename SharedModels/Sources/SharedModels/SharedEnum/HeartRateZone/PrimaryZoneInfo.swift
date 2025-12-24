//
//  PrimaryZoneInfo.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 23/12/2025.
//
import Foundation

/// Represents the primary heart rate zone during a workout.
///
/// Contains information about which heart rate zone the user spent
/// the most time in during a workout session, along with the duration.
///
/// ## Example
/// ```swift
/// let zoneInfo = PrimaryZoneInfo(zone: .aerobic, duration: 1420)
/// // User spent 23 min 40 sec in aerobic zone
/// ```
public struct PrimaryZoneInfo: Equatable, Sendable {
    
    /// The heart rate zone where the user spent the most time.
    public let zone: HeartRateZone
    
    /// Total time spent in the primary zone, in seconds.
    public let duration: TimeInterval
    
    /// Creates a new PrimaryZoneInfo instance.
    ///
    /// - Parameters:
    ///   - zone: The dominant heart rate zone
    ///   - duration: Time spent in that zone in seconds
    public init(zone: HeartRateZone, duration: TimeInterval) {
        self.zone = zone
        self.duration = duration
    }
}
