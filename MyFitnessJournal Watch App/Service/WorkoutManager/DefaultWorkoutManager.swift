//
//  DefaultWorkoutManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Foundation
import HealthKit

final class DefaultWorkoutManager: WorkoutManager {
    
    let healthStore = HKHealthStore()
    
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
}

