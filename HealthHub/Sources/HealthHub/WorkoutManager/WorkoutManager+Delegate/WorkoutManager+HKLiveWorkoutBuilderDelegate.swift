//
//  WorkoutManager+HKLiveWorkoutBuilderDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import HealthKit
import SharedModels

@available(iOS 26.0, *)
extension DefaultWorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        guard let event = workoutBuilder.workoutEvents.last else {
            return
        }
        print("workout builder did collect event=\(event)")
    }

    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        print("iOS: Collected data for \(collectedTypes.count) types")
        
        var allStatistics: [HKStatistics] = []
        
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }
            
            Task { @MainActor in
                self.updateForStatistics(statistics)
            }
            
            allStatistics.append(statistics)
        }
        
    }
    
    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didEnd workoutActivity: HKWorkoutActivity) {
        print("workout builder did end workout_activity=\(workoutActivity)")
    }
    
}
