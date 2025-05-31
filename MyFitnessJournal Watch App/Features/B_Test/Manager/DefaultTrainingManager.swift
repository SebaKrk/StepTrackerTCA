//
//  DefaultTrainingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import HealthKit

final class DefaultTrainingManager: NSObject, TrainingManager {
    
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType.workoutType()
    ]
    
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType()
    ]
    
    
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            // Handle error.
        }
    }
    
    let healthStore = HKHealthStore()
    
    var session: HKWorkoutSession?
    
    var builder: HKLiveWorkoutBuilder?
    
    var workout: HKWorkout?
    
    var workoutMetricsContinuation: AsyncStream<WorkoutMetrics>.Continuation?
    
    var workoutSessionContinuation: AsyncStream<Bool>.Continuation?
    
    var metrics = WorkoutMetrics(averageHeartRate: 0,
                                 heartRate: 0,
                                 activeEnergy: 0)
    
    var workoutMetricsStream: AsyncStream<WorkoutMetrics> {
        AsyncStream { continuation in
            self.workoutMetricsContinuation = continuation
        }
    }
    
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
    
    func setValueForSumaryView(_ value: Bool) {
        showingSummaryView = value
    }
    
    var workoutSessionIsRunning: Bool = false
    
    func setSelectedWorkout(_ type: HKWorkoutActivityType?) {
        selectedWorkout = type
    }
    
    func togglePause() {
        print("toggle pause - current state: \(workoutSessionIsRunning)")
        
        guard let session = session else {
            print("❌ No session to pause/resume")
            return
        }
        
        if workoutSessionIsRunning {
            // Wstrzymaj sesję HealthKit
            session.pause()
            print("⏸️ Pausing workout session")
        } else {
            // Wznów sesję HealthKit
            session.resume()
            print("▶️ Resuming workout session")
        }
        
        // Lokalny stan zostanie zaktualizowany w delegate method
    }
    
    func endWorkout() {
        print("end workout")
        
        guard let session = session else {
            print("❌ No session to end")
            return
        }
        
        // Zakończ sesję HealthKit
        session.end()
        print("🛑 Ending workout session")
        
        // Stan zostanie zaktualizowany w delegate method
        
        showingSummaryView = true
        print("showingSummaryView")
    }
    
    func workoutSessionIsRunningStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.workoutSessionContinuation = continuation
            continuation.yield(self.workoutSessionIsRunning)
        }
    }
    
    // MARK: - API
    
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
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: configuration)
        
        
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
    }

    
}

extension DefaultTrainingManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            // Zaktualizuj stan na podstawie rzeczywistego stanu HealthKit
            self.workoutSessionIsRunning = toState == .running
            print("🔄 Workout session changed from \(fromState.rawValue) to \(toState.rawValue)")
            print("📊 workoutSessionIsRunning: \(self.workoutSessionIsRunning)")
            
            // Wyślij aktualizację do streamów
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
        }
        
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("❌ Workout session failed with error: \(error)")
    }
}

extension DefaultTrainingManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
