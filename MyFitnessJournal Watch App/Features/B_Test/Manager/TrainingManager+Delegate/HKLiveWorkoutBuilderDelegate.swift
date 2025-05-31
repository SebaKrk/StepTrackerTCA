//
//  HKLiveWorkoutBuilderDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

extension DefaultTrainingManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
