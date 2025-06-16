//
//  HealthAuthorizationManager.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
 
public final class DefaultAuthorizationManager: AuthorizationManager {
 
    // MARK: - HealthKit Configuration
    
    let healthStore: HKHealthStore
    
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned)
    ]
    
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType(),
        HKObjectType.workoutType()
    ]
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Authorization
    public func requestAuthorization() {
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Authorization: \(success)")
            }
        }
    }
    
}
