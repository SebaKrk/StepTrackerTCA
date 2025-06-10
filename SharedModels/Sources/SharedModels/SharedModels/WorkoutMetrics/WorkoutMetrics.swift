//
//  WorkoutMetrics.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

/// Represents key metrics during a workout session.
public struct WorkoutMetrics: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// The average heart rate measured throughout the workout session, in beats per minute.
    public var averageHeartRate: Double
    
    /// The current heart rate at a specific moment during the workout, in beats per minute.
    public var heartRate: Double
    
    /// The amount of active energy burned during the workout session, measured in kilocalories.
    public var activeEnergy: Double
    
    // MARK: - Lifecycle
    
    public init(averageHeartRate: Double, heartRate: Double, activeEnergy: Double) {
        self.averageHeartRate = averageHeartRate
        self.heartRate = heartRate
        self.activeEnergy = activeEnergy
    }
    
}
