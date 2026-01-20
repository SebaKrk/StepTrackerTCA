//
//  TimerActivityAttributes.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 17/01/2026.
//

import ActivityKit
import Foundation

/// Attributes for Timer Live Activity.
/// Contains both fixed (non-changing) and dynamic (ContentState) properties for displaying timer with heart rate metrics.
public struct TimerActivityAttributes: ActivityAttributes {
    
    // MARK: - Fixed Properties
    
    /// The name of the timer (e.g., "Stoper", "Timer")
    public let timerName: String
    
    /// The start time of the timer
    public let startTime: Date
    
    // MARK: - Lifecycle
    
    public init(timerName: String, startTime: Date) {
        self.timerName = timerName
        self.startTime = startTime
    }
    
    // MARK: - ContentState
    
    /// Dynamic state that changes during timer session
    public struct ContentState: Codable, Hashable {
        
        /// Current heart rate in beats per minute
        public var heartRate: Double
        
        /// Current heart rate zone
        public var heartRateZone: HeartRateZone
        
        /// Elapsed time in seconds (snapshot)
        public var elapsedTime: TimeInterval
        
        /// Whether timer is currently running
        public var isRunning: Bool
        
        /// Date when the timer start was adjusted (accounting for pauses)
        /// Crucial for displaying live timer in Live Activity
        public var adjustedStartDate: Date
        
        /// Date when timer was paused (nil if running)
        public var pauseDate: Date?
        
        // MARK: - Lifecycle
        
        public init(
            heartRate: Double,
            heartRateZone: HeartRateZone,
            elapsedTime: TimeInterval,
            isRunning: Bool,
            adjustedStartDate: Date,
            pauseDate: Date? = nil
        ) {
            self.heartRate = heartRate
            self.heartRateZone = heartRateZone
            self.elapsedTime = elapsedTime
            self.isRunning = isRunning
            self.adjustedStartDate = adjustedStartDate
            self.pauseDate = pauseDate
        }
    }
}

// MARK: - Preview Data

extension TimerActivityAttributes {
    /// Preview data for development and testing
    public static var preview: TimerActivityAttributes {
        TimerActivityAttributes(
            timerName: "Stoper",
            startTime: Date()
        )
    }
}

extension TimerActivityAttributes.ContentState {
    /// Preview state with timer running
    public static var running: TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            heartRate: 72,
            heartRateZone: .recovery,
            elapsedTime: 125.5,
            isRunning: true,
            adjustedStartDate: Date().addingTimeInterval(-125.5)
        )
    }
    
    /// Preview state with timer paused
    public static var paused: TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            heartRate: 68,
            heartRateZone: .resting,
            elapsedTime: 256.3,
            isRunning: false,
            adjustedStartDate: Date().addingTimeInterval(-256.3),
            pauseDate: Date()
        )
    }
}
