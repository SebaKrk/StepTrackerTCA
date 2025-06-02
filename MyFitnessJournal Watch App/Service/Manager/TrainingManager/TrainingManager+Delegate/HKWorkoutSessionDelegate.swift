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
        print("🔄 DELEGATE CALLED: \(fromState.rawValue) -> \(toState.rawValue)")
        
        DispatchQueue.main.async {
            self.workoutSessionIsRunning = toState == .running
            print("📊 workoutSessionIsRunning: \(self.workoutSessionIsRunning)")
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
        }
        
        if toState == .ended {
            print("🛑 Session ENDED - starting finalization")
            builder?.endCollection(withEnd: date) { (success, error) in
                print("📝 endCollection - success: \(success), error: \(error?.localizedDescription ?? "none")")
                
                self.builder?.finishWorkout { (workout, error) in
                    print("✅ finishWorkout - workout: \(workout != nil ? "SUCCESS" : "NIL"), error: \(error?.localizedDescription ?? "none")")
                    
                    DispatchQueue.main.async {
                        self.workout = workout
                        print("💾 Workout saved to property at: \(Date()): \(self.workout != nil)")
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("❌ Workout session failed with error: \(error)")
    }
    
}



//    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
//        DispatchQueue.main.async {
//            // Zaktualizuj stan na podstawie rzeczywistego stanu HealthKit
//            self.workoutSessionIsRunning = toState == .running
//            print("🔄 Workout session changed from \(fromState.rawValue) to \(toState.rawValue)")
//            print("📊 workoutSessionIsRunning: \(self.workoutSessionIsRunning)")
//
//            // Wyślij aktualizację do streamów
//            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
//        }
//
//        if toState == .ended {
//            builder?.endCollection(withEnd: date) { (success, error) in
//                self.builder?.finishWorkout { (workout, error) in
//                    DispatchQueue.main.async {
//                        self.workout = workout
//                    }
//                }
//            }
//        }
//    }
