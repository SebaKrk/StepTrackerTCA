//
//  WorkoutSummary.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import Foundation
import HealthKit

/// Combines detailed HealthKit workout data with live workout metrics.
struct WorkoutSummary: Equatable {
    
    /// The finalized HealthKit workout object.
    let workout: HKWorkout?
    
    /// Live metrics gathered during the workout session.
    let metrics: WorkoutMetrics
    
}
