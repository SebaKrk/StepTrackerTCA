//
//  HealthAuthorizationManager.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
 
public final class DefaultAuthorizationManager: AuthorizationManager {
 
    // MARK: - Properties
    
    public let healthStore: HKHealthStore

    // MARK: - HealthKit Configuration
    
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass),
        HKQuantityType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned)
    ]

    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType(),
        HKObjectType.workoutType()
    ]
    
    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Authorization

    /// Requests authorization from HealthKit to read and/or write the required data types.
    public func requestAuthorization() async -> Result<Bool, Error> {
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
}
