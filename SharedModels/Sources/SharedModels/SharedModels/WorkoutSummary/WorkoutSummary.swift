//
//  WorkoutSummary.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import Foundation
import HealthKit

/// Combines detailed HealthKit workout data with live workout metrics.
public struct WorkoutSummary: Equatable, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// The finalized HealthKit workout object.
    public let workout: HKWorkout?
    
    /// Live metrics gathered during the workout session.
    public let metrics: WorkoutMetrics
    
    // MARK: - Lifecycle
    
    public init(workout: HKWorkout?, metrics: WorkoutMetrics) {
        self.workout = workout
        self.metrics = metrics
    }
    
}
