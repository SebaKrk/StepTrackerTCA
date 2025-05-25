//
//  WorkoutManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Foundation
import HealthKit

protocol WorkoutManager {
    
    var healthStore: HKHealthStore { get }
    
    var shareTypes: Set<HKSampleType> { get }
    
    var readTypes: Set<HKObjectType> { get }
    
    var selectedWorkout: HKWorkoutActivityType? { get set }
    
    var session: HKWorkoutSession? { get set }
    
    var builder: HKLiveWorkoutBuilder? { get set }
    
    
    // MARK: - API
    
    func requestAuthorization()
    
    func updateForStatistics(_ statistics: HKStatistics?)
    
    func startWorkout(workoutType: HKWorkoutActivityType)
    
    // MARK: - Workout Metrics Accessors
    
    var showingSummaryView: Bool { get set }
    
    var workoutSessionIsRunning: Bool { get }
    
    var metrics: WorkoutMetrics { get }
    
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> { get }
    
    // MARK: - Session State Control
    
    func togglePause()

    func endWorkout()
    
}


