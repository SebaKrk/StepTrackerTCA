//
//  HKWorkoutSessionDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

extension DefaultTrainingManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        DispatchQueue.main.async {
            self.workoutSessionIsRunning = toState == .running
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
        }
        
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                
                self.builder?.finishWorkout { (workout, error) in
                    
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("❌ Workout session failed with error: \(error)")
    }
    
}
