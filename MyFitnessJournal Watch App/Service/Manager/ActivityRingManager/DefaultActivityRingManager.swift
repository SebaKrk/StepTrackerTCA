//
//  DefaultActivityRingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/06/2025.
//

import HealthKit

final class DefaultActivityRingManager: ActivityRingManager {
    
    // MARK: - Properties
    
    let healthStore: HKHealthStore

    // MARK: - Lifecycle
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - API
    
    func fetchTodaySummary() async throws -> ActivityRingData {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: components)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let summary = summaries?.first {
                    let data = ActivityRingData(
                        moveValue: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                        moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                        exerciseValue: summary.appleExerciseTime.doubleValue(for: .minute()),
                        exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute()),
                        standValue: summary.appleStandHours.doubleValue(for: .count()),
                        standGoal: summary.appleStandHoursGoal.doubleValue(for: .count())
                    )
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "NoSummary", code: 0))
                }
            }
            healthStore.execute(query)
        }
    }
    
}
