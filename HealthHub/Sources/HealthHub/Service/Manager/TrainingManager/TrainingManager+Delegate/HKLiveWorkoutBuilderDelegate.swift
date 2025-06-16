//
//  HKLiveWorkoutBuilderDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

#if os(watchOS)
// MARK: - HKLiveWorkoutBuilderDelegate (watchOS Only)
extension DefaultTrainingManager: HKLiveWorkoutBuilderDelegate {

    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("⌚ watchOS: Workout builder collected event")
        // Handle workout events if needed
    }
    
    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                              didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        print("⌚ watchOS: Collected data for \(collectedTypes.count) types")
        
        var allStatistics: [HKStatistics] = []
        
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }
            
            // Update local metrics immediately on watchOS
            Task { @MainActor in
                self.updateForStatistics(statistics)
            }
            
            allStatistics.append(statistics)
        }
        
        // Send collected data to iOS companion
        sendStatisticsToCompanion(allStatistics)
    }
    
    // MARK: - Private Helper Methods
    
    private func sendStatisticsToCompanion(_ statistics: [HKStatistics]) {
        guard !statistics.isEmpty else {
            print("⚠️ watchOS: No statistics to send")
            return
        }
        
        Task {
            do {
                let archivedData = try NSKeyedArchiver.archivedData(
                    withRootObject: statistics,
                    requiringSecureCoding: true
                )
                
                guard !archivedData.isEmpty else {
                    print("⚠️ watchOS: Encoded data is empty")
                    return
                }
                
                await sendData(archivedData)
                print("✅ watchOS: Sent \(statistics.count) statistics to iOS companion")
                
            } catch {
                print("❌ watchOS: Failed to archive statistics: \(error)")
            }
        }
    }
}

#endif
