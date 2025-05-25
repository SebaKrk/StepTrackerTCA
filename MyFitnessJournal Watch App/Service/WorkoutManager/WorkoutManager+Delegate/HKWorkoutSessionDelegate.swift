//
//  HKWorkoutSessionDelegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import Foundation
import HealthKit

extension DefaultWorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    ///
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    ///
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            
            updateForStatistics(statistics)
        }
    }
    
}
