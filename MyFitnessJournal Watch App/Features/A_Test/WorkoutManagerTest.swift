//
//  WorkoutManagerTest.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/05/2025.
//

import HealthKit

final class WorkoutManagerTest: NSObject, ObservableObject {
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    var heartRateContinuation: AsyncStream<Double>.Continuation?

    var heartRateStream: AsyncStream<Double> {
        AsyncStream { continuation in
            self.heartRateContinuation = continuation
        }
    }
    
    var heartRate: Double = 0

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                if let newHeartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    print("💓 Updated heart rate: \(newHeartRate)")
                    self.heartRate = newHeartRate
                    self.heartRateContinuation?.yield(newHeartRate)
                }
            default:
                break
            }
        }
    }

    func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()

            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            builder?.delegate = self
            session?.delegate = self

            session?.startActivity(with: .now)
            builder?.beginCollection(withStart: .now) { _, _ in }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
}

extension WorkoutManagerTest: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("🏃‍♂️ didCollectDataOf: \(collectedTypes)")
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateForStatistics(statistics)
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension WorkoutManagerTest: HKWorkoutSessionDelegate {
//    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("🔄 Workout session changed from \(fromState.rawValue) to \(toState.rawValue)")
    }
}
