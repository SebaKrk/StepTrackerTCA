//
//  HKLiveWorkoutBuilderDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

/// HKLiveWorkoutBuilderDelegate
extension DefaultTrainingManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            Task { @MainActor in
                self.updateForStatistics(statistics)
            }
        }
    }
    
    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didFinishWorkout workout: HKWorkout) {
        Task { @MainActor in
            self.workout = workout
        }
    }
}

