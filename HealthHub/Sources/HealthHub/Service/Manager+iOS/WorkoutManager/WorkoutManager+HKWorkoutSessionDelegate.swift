//
//  WorkoutManager+HKWorkoutSessionDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import HealthKit
import SharedModels

// MARK: - HKWorkoutSessionDelegate (Both Platforms)
@available(iOS 26.0, *)
extension DefaultWorkoutManager: HKWorkoutSessionDelegate {
    
    public  func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        
        print("💫 Session state changed from \(fromState.rawValue) to \(toState.rawValue)")
        Task { @MainActor in
            self.workoutSessionIsRunning = toState == .running
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
        }
        
        if toState == .stopped {
            handleWorkoutEnd(date: date)
        }
    }

    public  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed with error: \(error)")
    }
}
