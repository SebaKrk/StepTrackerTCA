//
//  DefaultTrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import HealthKit

final class DefaultTrainingManager: NSObject, TrainingManager {

    // MARK: - HealthKit Configuration
    
    let healthStore = HKHealthStore()
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType.workoutType()
    ]
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType()
    ]

    // MARK: - Workout Session State
    
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var workout: HKWorkout?

    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }
    var showingSummaryView: Bool = false {
        didSet {
            print("showingSummaryView changed to: \(showingSummaryView)")
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    var workoutSessionIsRunning: Bool = false

    // MARK: - Workout Metrics
    var metrics = WorkoutMetrics(
        averageHeartRate: 0,
        heartRate: 0,
        activeEnergy: 0
    )
    var workoutMetricsContinuation: AsyncStream<WorkoutMetrics>.Continuation?
    var workoutSessionContinuation: AsyncStream<Bool>.Continuation?

    // MARK: - Authorization
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            // Handle error.
        }
    }

    // MARK: - State
    func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        selectedWorkout = type
    }

    func setValueForSumaryView(_ value: Bool) {
        showingSummaryView = value
    }

    // MARK: - Streams
    func workoutSessionIsRunningStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.workoutSessionContinuation = continuation
            continuation.yield(self.workoutSessionIsRunning)
        }
    }
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        AsyncStream { continuation in
            self.workoutMetricsContinuation = continuation
        }
    }

    // MARK: - Workout Management
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        print("start workout: \(workoutType)")

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("❌ Error creating workout session: \(error)")
            return
        }

        session?.delegate = self
        builder?.delegate = self

        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            if success {
                print("✅ Workout collection started successfully")
            } else {
                print("❌ Error starting workout collection: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }

    // MARK: - Workout Data Handling
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

    // MARK: - Helpers
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        metrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
    }

}
