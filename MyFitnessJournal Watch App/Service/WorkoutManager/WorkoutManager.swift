//
//  WorkoutManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import Foundation
import HealthKit

protocol WorkoutManager {
    
    var healthStore: HKHealthStore { get }
    
    var shareTypes: Set<HKSampleType> { get }
    
    var readTypes: Set<HKObjectType> { get }
    
    func requestAuthorization()
}


