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

    var heartRateHandler: ((Double) -> Void)?

    func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
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
        guard collectedTypes.contains(HKQuantityType.quantityType(forIdentifier: .heartRate)!) else { return }

        guard let stats = workoutBuilder.statistics(for: .quantityType(forIdentifier: .heartRate)!) else { return }
        let bpmUnit = HKUnit(from: "count/min")
        let value = stats.mostRecentQuantity()?.doubleValue(for: bpmUnit)
        if let value = value {
            heartRateHandler?(value)
        }
        
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension WorkoutManagerTest: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}
