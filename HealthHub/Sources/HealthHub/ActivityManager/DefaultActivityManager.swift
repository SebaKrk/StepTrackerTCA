//
//  DefaultActivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 14/12/2025.
//

import ComposableArchitecture
import HealthKit
import SharedModels

public final class DefaultActivityManager: ActivityManager {
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    
    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - API
    
    /// Fetches a list of workouts from the specified time period.
    public func fetchWorkouts(
        for days: Int,
        sortBy option: ActivitiesSortOption = .newestFirst
    ) async throws -> [HKWorkout] {
        try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
            for: days,
            sortOption: option,
            healthStore: healthStore
        )
    }
    
    /// Fetches heart rate samples recorded during a specific workout.
    public func fetchHeartRateSamples(
        for workout: HKWorkout
    ) async throws -> [HKQuantitySample] {
        try await HealthKitQueryBuilder.fetchHeartRateSamples(
            for: workout,
            healthStore: healthStore
        )
    }
    
    /// Fetches heart rate measurement after workout ends for HR Recovery calculation.
    public func fetchHeartRateAfterWorkout(
        workout: HKWorkout,
        afterSeconds: TimeInterval
    ) async throws -> Double? {
        let heartRateType = HKQuantityType(.heartRate)
        
        // Okno: koniec treningu do +90 sekund (margines)
        let windowStart = workout.endDate
        let windowEnd = workout.endDate.addingTimeInterval(afterSeconds + 30)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: windowStart,
            end: windowEnd,
            options: .strictStartDate
        )
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: heartRateType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .forward)],
            limit: 10
        )
        
        let results = try await descriptor.result(for: healthStore)
        
        // Znajdź pomiar najbliższy targetTime (endDate + afterSeconds)
        let targetTime = workout.endDate.addingTimeInterval(afterSeconds)
        
        let closestSample = results.min { sample1, sample2 in
            abs(sample1.startDate.timeIntervalSince(targetTime)) < abs(sample2.startDate.timeIntervalSince(targetTime))
        }
        
        guard let sample = closestSample else { return nil }
        
        return sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
    }
}
