//
//  DefaultTrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import HealthKit

final class DefaultTrainingManager: NSObject, TrainingManager {

    // MARK: - HealthKit Configuration
    
    let healthStore: HKHealthStore
    
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
    
    // MARK: - Livecycle
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - API
    
    func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        selectedWorkout = type
    }

    func setValueForSummaryView(_ value: Bool) {
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
    
    func getWorkout() -> HKWorkout? {
        print("🔍 getWorkout() called - workout: \(workout != nil ? "exists" : "nil")")
        print("⏩️ workout:\(workout)")
        return workout
    }

    func getWorkoutMetrics() -> WorkoutMetrics {
        print("🔍 getWorkoutMetrics() - activeEnergy: \(metrics.activeEnergy)")
        return metrics
    }
}
