//
//  HealthKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import Foundation
import HealthKit

/// A protocol defining the required properties for managing HealthKit data.
protocol HealthKitManager {
    
    /// The HealthKit store used to access and manage HealthKit data.
    ///
    /// `HKHealthStore` is responsible for interacting with the HealthKit framework.
    var store: HKHealthStore { get }
    
    /// A set of sample types that the manager requests write access to.
    var shareTypes: Set<HKSampleType> { get }
    
    /// A set of object types that the manager requests read access to.
    var readTypes: Set<HKObjectType> { get }
    
}
