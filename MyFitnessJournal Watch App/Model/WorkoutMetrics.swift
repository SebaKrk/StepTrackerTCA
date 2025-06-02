//
//  WorkoutMetrics.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation

/// Represents key metrics during a workout session.
struct WorkoutMetrics: Equatable {
    
    /// The average heart rate measured throughout the workout session, in beats per minute.
    var averageHeartRate: Double
    
    /// The current heart rate at a specific moment during the workout, in beats per minute.
    var heartRate: Double
    
    /// The amount of active energy burned during the workout session, measured in kilocalories.
    var activeEnergy: Double
    
}
