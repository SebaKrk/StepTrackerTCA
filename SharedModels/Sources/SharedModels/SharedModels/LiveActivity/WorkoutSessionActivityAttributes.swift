//
//  WorkoutSessionActivityAttributes.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 15/01/2026.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Attributes for Workout Session Live Activity.
/// Contains both fixed (non-changing) and dynamic (ContentState) properties for displaying workout metrics on the lock screen.
public struct WorkoutSessionActivityAttributes: ActivityAttributes {
    
    // MARK: - Fixed Properties
    
    /// The name of the workout session (e.g., "Running", "Cycling")
    public let workoutName: String
    
    /// The start time of the workout session
    public let startTime: Date
    
    // MARK: - Lifecycle
    
    public init(workoutName: String, startTime: Date) {
        self.workoutName = workoutName
        self.startTime = startTime
    }
    
    // MARK: - ContentState
    
    /// Dynamic state that changes throughout the workout session
    public struct ContentState: Codable, Hashable {
        
        /// Current heart rate in beats per minute
        public var heartRate: Double
        
        /// Current heart rate zone
        public var heartRateZone: HeartRateZone
        
        /// Current heart rate as percentage of max heart rate
        public var heartRatePercentage: Int
        
        /// Total active energy burned in kilocalories
        public var activeEnergy: Double
        
        /// Maximum heart rate recorded during this session
        public var maxHeartRate: Int
        
        /// Average heart rate during this session
        public var averageHeartRate: Int

        /// `true` while the HealthKit mirroring link with the Watch is down (IOS-00098-G).
        /// The workout keeps running on the Watch — the Live Activity shows a stale-data
        /// indicator instead of silently frozen metrics.
        public var isWatchConnectionLost: Bool

        // MARK: - Lifecycle

        public init(
            heartRate: Double,
            heartRateZone: HeartRateZone,
            heartRatePercentage: Int,
            activeEnergy: Double,
            maxHeartRate: Int,
            averageHeartRate: Int,
            isWatchConnectionLost: Bool = false
        ) {
            self.heartRate = heartRate
            self.heartRateZone = heartRateZone
            self.heartRatePercentage = heartRatePercentage
            self.activeEnergy = activeEnergy
            self.maxHeartRate = maxHeartRate
            self.averageHeartRate = averageHeartRate
            self.isWatchConnectionLost = isWatchConnectionLost
        }
    }
}

// MARK: - Preview Data

extension WorkoutSessionActivityAttributes {
    /// Preview data for development and testing
    public static var preview: WorkoutSessionActivityAttributes {
        WorkoutSessionActivityAttributes(
            workoutName: "Running",
            startTime: Date()
        )
    }
}

extension WorkoutSessionActivityAttributes.ContentState {
    /// Preview state with resting heart rate
    public static var resting: WorkoutSessionActivityAttributes.ContentState {
        WorkoutSessionActivityAttributes.ContentState(
            heartRate: 65,
            heartRateZone: .resting,
            heartRatePercentage: 42,
            activeEnergy: 0,
            maxHeartRate: 65,
            averageHeartRate: 65
        )
    }
    
    /// Preview state with aerobic zone heart rate
    public static var aerobic: WorkoutSessionActivityAttributes.ContentState {
        WorkoutSessionActivityAttributes.ContentState(
            heartRate: 145,
            heartRateZone: .aerobic,
            heartRatePercentage: 75,
            activeEnergy: 234.5,
            maxHeartRate: 152,
            averageHeartRate: 138
        )
    }
    
    /// Preview state with threshold zone heart rate
    public static var threshold: WorkoutSessionActivityAttributes.ContentState {
        WorkoutSessionActivityAttributes.ContentState(
            heartRate: 168,
            heartRateZone: .threshold,
            heartRatePercentage: 87,
            activeEnergy: 456.8,
            maxHeartRate: 172,
            averageHeartRate: 155
        )
    }
    
    /// Preview state with anaerobic zone heart rate
    public static var anaerobic: WorkoutSessionActivityAttributes.ContentState {
        WorkoutSessionActivityAttributes.ContentState(
            heartRate: 182,
            heartRateZone: .anaerobic,
            heartRatePercentage: 94,
            activeEnergy: 589.2,
            maxHeartRate: 185,
            averageHeartRate: 165
        )
    }
}
#endif
