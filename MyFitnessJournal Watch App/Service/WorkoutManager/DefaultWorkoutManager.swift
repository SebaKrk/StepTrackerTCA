//
//  DefaultWorkoutManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Foundation
import HealthKit

final class DefaultWorkoutManager: NSObject, WorkoutManager {
    
    // MARK: - Properties
    
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }
    
    var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()

    var session: HKWorkoutSession?
    
    var builder: HKLiveWorkoutBuilder?

    let shareTypes: Set<HKSampleType> = [
        HKQuantityType.workoutType()
    ]
    
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType()
    ]
    
    // MARK: - Workout Metrics
    
    var workout: HKWorkout?
    
    var workoutMetricsContinuation: AsyncStream<WorkoutMetrics>.Continuation?

    var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        AsyncStream { continuation in
            self.workoutMetricsContinuation = continuation
        }
    }
    
    var metrics = WorkoutMetrics(averageHeartRate: 0,
                                 heartRate: 0,
                                 activeEnergy: 0)
    
    //var averageHeartRate: Double = 0
    //var heartRate: Double = 0
    //var activeEnergy: Double = 0
    
    var workoutSessionIsRunning = false
    
    // MARK: - API
    
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            // Handle error.
        }
    }
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        session?.delegate = self
        builder?.delegate = self

        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
        }
    }
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                
                self.metrics.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.metrics.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                
                self.workoutMetricsContinuation?.yield(self.metrics)
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                
                self.metrics.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
                
                self.workoutMetricsContinuation?.yield(self.metrics)
            default:
                return
            }
        }
    }
    
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        metrics = WorkoutMetrics(averageHeartRate: 0,
                                 heartRate: 0,
                                 activeEnergy: 0)
//        activeEnergy = 0
//        averageHeartRate = 0
//        heartRate = 0
    }
    
}

struct WorkoutMetrics: Equatable {
    
    var averageHeartRate: Double
    
    var heartRate: Double
    
    var activeEnergy: Double
}
