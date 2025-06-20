//
//  DefaultTrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import HealthKit
import SharedModels

public final class DefaultTrainingManager: NSObject, TrainingManager, @unchecked Sendable {
    
    // MARK: - HealthKit Configuration
    let healthStore: HKHealthStore
    
    // MARK: - Workout Session State
    var session: HKWorkoutSession?
    
#if os(watchOS)
    public var builder: HKLiveWorkoutBuilder?
#endif
    
    var workout: HKWorkout?
    
#if os(watchOS)
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            Task {
                await startWorkout(workoutType: selectedWorkout)
            }
        }
    }
#else
    var selectedWorkout: HKWorkoutActivityType?
#endif
    
    var showingSummaryView: Bool = false {
        didSet {
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
    
    // MARK: - Lifecycle
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        super.init()    
#if os(iOS)
        setupRemoteSessionHandler()
#endif
    }
    
    // MARK: - TrainingManager Protocol Implementation
    
    public func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        selectedWorkout = type
    }
    
    public func setValueForSummaryView(_ value: Bool) {
        showingSummaryView = value
    }
    
    public func workoutSessionIsRunningStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.workoutSessionContinuation = continuation
            continuation.yield(self.workoutSessionIsRunning)
        }
    }
    
    public var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        AsyncStream { continuation in
            self.workoutMetricsContinuation = continuation
        }
    }
    
    public func getWorkout() -> HKWorkout? {
        workout
    }
    
    public func getWorkoutMetrics() -> WorkoutMetrics {
        metrics
    }
    
    // MARK: - Workout Management
    
#if os(watchOS)
    internal func startWorkout(workoutType: HKWorkoutActivityType) async {
        print("⌚ watchOS: Starting workout: \(workoutType)")
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("❌ watchOS: Error creating workout session: \(error)")
            return
        }
        
        session?.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        do {
            print("⌚ watchOS: Starting mirroring to companion device")
            try await session?.startMirroringToCompanionDevice()
            print("✅ watchOS: Mirroring started successfully")
        } catch {
#if targetEnvironment(simulator)
            print("🔧 Simulator: Mirroring not available (expected in simulator)")
#else
            print("❌ watchOS: Unable to start mirrored workout: \(error.localizedDescription)")
#endif
        }
        
        let start = Date()
        session?.startActivity(with: start)
        
        await withCheckedContinuation { continuation in
            builder?.beginCollection(withStart: start) { (success, error) in
                if success {
                    print("✅ watchOS: Workout collection started successfully")
                } else {
                    print("❌ watchOS: Error starting workout collection: \(error?.localizedDescription ?? "Unknown")")
                }
                continuation.resume()
            }
        }
    }
    
#endif

    internal func sendData(_ data: Data) async {
        print("🔄 sendData called with \(data.count) bytes")
        do {
            try await session?.sendToRemoteWorkoutSession(data: data)
            print("✅ Data sent successfully")
        } catch {
            let nsError = error as NSError
            
            if nsError.domain == "com.apple.healthkit" && nsError.code == 300 {
#if targetEnvironment(simulator)
                print("🔧 Simulator: Remote device communication not available (expected)")
#else
                print("❌ Failed to send data: \(error)")
#endif
            } else {
                print("❌ Failed to send data: \(error)")
            }
        }
    }
    
    // MARK: - Workout Data Handling
    
    internal func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            self.metrics.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            self.metrics.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let energyUnit = HKUnit.kilocalorie()
            self.metrics.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            
        default:
            return
        }
        
        // Yield updated metrics to stream
        let currentMetrics = self.metrics
        self.workoutMetricsContinuation?.yield(currentMetrics)
    }
    
    // MARK: - Helpers
    
    internal func resetWorkout() {
        print("🔄 Resetting workout state")
        selectedWorkout = nil
#if os(watchOS)
        builder = nil
#endif
        workout = nil
        session = nil
        metrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        workoutSessionIsRunning = false
    }
}
