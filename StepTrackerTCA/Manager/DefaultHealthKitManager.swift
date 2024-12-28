//
//  DefaultHealthKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import HealthKit
import Observation

/// The default implementation of the `HealthKitManager` protocol.
///
/// This class provides the necessary configuration and functionality for requesting
/// and managing HealthKit data, such as step count and body mass.
@Observable
class DefaultHealthKitManager: HealthKitManager {
    
    /// The HealthKit store used to access and manage HealthKit data.
    ///
    /// `HKHealthStore` is responsible for interacting with the HealthKit framework.
    /// It is used for requesting permissions, fetching, and saving data.
    let store = HKHealthStore()
    
    /// A set of sample types that the manager requests write access to.
    ///
    /// This defines which types of data the app can write to HealthKit. For example,
    /// this implementation supports writing step count and body mass data.
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass)
    ]
    
    /// A set of object types that the manager requests read access to.
    ///
    /// This defines which types of data the app can read from HealthKit. For example,
    /// this implementation supports reading step count and body mass data.
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass)
    ]
    
}
