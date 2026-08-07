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
        ///Activity & Steps
        HKQuantityType(.stepCount),

        ///Body Metrics
        HKQuantityType(.bodyMass),

        /// Workouts & Heart Rate
        HKQuantityType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),

        /// Distance — required for iPhone-primary tor (Tor B) outdoor activities
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),

        /// Route — write access for HKWorkoutRouteBuilder (outdoor rides);
        /// read side is already in `readTypes` for the history map.
        HKSeriesType.workoutRoute()
    ]

    let readTypes: Set<HKObjectType> = [
        /// Personal Info (Characteristics)
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex),
        
        /// Body Metrics
        HKQuantityType(.height),
        HKQuantityType(.bodyMass),
        
        /// Heart Rate & Health
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        
        /// Activity & Steps
        HKQuantityType(.stepCount),
        HKObjectType.activitySummaryType(),
        
        /// Workouts & Energy
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
        HKSeriesType.workoutRoute(),

        /// Distance — required for iPhone-primary tor (Tor B) outdoor activities
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),

        /// Running dynamics (Watch, watchOS 9+) — route drill-in cards
        HKQuantityType(.runningPower),
        HKQuantityType(.runningStrideLength),
        HKQuantityType(.runningVerticalOscillation),
        HKQuantityType(.runningGroundContactTime),

        /// Activity Rings - Hourly Data
        HKQuantityType(.appleExerciseTime),
        HKCategoryType(.appleStandHour),
        
        /// Sleep
        HKCategoryType(.sleepAnalysis)
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
    
    /// Returns a dictionary mapping each share type to its current authorization status.
//    public func authorizationStatuses() -> [HKSampleType: HKAuthorizationStatus] {
//        var statuses: [HKSampleType: HKAuthorizationStatus] = [:]
//        for type in shareTypes {
//            let status = healthStore.authorizationStatus(for: type)
//            statuses[type] = status
//        }
//        return statuses
//    }
    
    /// Returns a dictionary mapping the name of each share type to a boolean indicating if it's authorized.
    public func authorizationStatuses() -> [String: Bool] {
        var statuses: [String: Bool] = [:]
        for type in shareTypes {
            let isAuthorized = healthStore.authorizationStatus(for: type) == .sharingAuthorized
            statuses[type.identifier] = isAuthorized
        }
        return statuses
    }
    
    /// Returns true if all share types are authorized for sharing.
    public func isAuthorizedForAllRequiredShareTypes() -> Bool {
        for type in shareTypes {
            if healthStore.authorizationStatus(for: type) != .sharingAuthorized {
                return false
            }
        }
        return true
    }
    
}
