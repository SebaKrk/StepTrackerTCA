//
//  HealthAuthorizationManager.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
 
final class DefaultAuthorizationManager: AuthorizationManager {
 
    // MARK: - HealthKit Configuration
    
    let healthStore: HKHealthStore
    
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType.workoutType()
    ]
    
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKObjectType.activitySummaryType()
    ]
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Authorization: \(success)")
            }
        }
    }
    
}
