//
//  HKWorkoutSessionDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

//import Foundation
//import HealthKit
//
///// HKWorkoutSessionDelegate
//extension DefaultTrainingManager: HKWorkoutSessionDelegate {
//    
//    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
//        
//        Task { @MainActor in
//            self.workoutSessionIsRunning = toState == .running
//            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
//        }
//        
//        if toState == .ended {
//            Task { @MainActor in
//                let currentBuilder = self.builder
//                
//                currentBuilder?.endCollection(withEnd: date) { (success, error) in
//                    currentBuilder?.finishWorkout { (workout, error) in
//                        Task { @MainActor in
//                            self.workout = workout
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
//        print("❌ Workout session failed with error: \(error)")
//    }
//}
