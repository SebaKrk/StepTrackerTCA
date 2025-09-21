//
//  WorkoutManagerStateControl.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import HealthKit

// MARK: - Session State Control
@available(iOS 26.0, *)
extension DefaultWorkoutManager {
    
    public func togglePause() {
        guard let session = session else {
            print("⚠️ No active session to toggle")
            return
        }
        
        if workoutSessionIsRunning {
            pause(session)
        } else {
            resume(session)
        }
    }
    
    public func endWorkout() {
        guard let session = session else {
            print("⚠️ No active session to end")
            return
        }
        print("🔚 Ending workout session")
        
        sessionState = .stopped
        session.stopActivity(with: .now)
        //session.end()
        
    }
    
    // MARK: - Private Helpers
    
    private func pause(_ session: HKWorkoutSession) {
        print("⏸️ Pausing workout session")
        session.pause()
    }
    
    private func resume(_ session: HKWorkoutSession) {
        print("▶️ Resuming workout session")
        session.resume()
    }
    
    // MARK: - Platform-specific Workout End Handling
    
    internal func handleWorkoutEnd(date: Date) {
        handleWorkoutEndOS(date: date)
        //        #if os(watchOS)
        //        handleWorkoutEndWatchOS(date: date)

        //        #else
        //        handleWorkoutEndIOS(date: date)
        //        #endif
    }
    
    private func handleWorkoutEndOS(date: Date) {
        Task { @MainActor in
            guard let builder = self.builder else {
                print("⚠️ iOS: No builder available for workout end")
                return
            }
            
            do {
                print("iOS: Ending collection and finishing workout")
                try await builder.endCollection(at: date)
                let finishedWorkout = try await builder.finishWorkout()
                self.workout = finishedWorkout
                
                self.session?.end()
                print("✅ iOS: Workout finished successfully")
                dump(workout)
            } catch {
                print("❌ iOS: Failed to end workout: \(error)")
            }
        }
    }
    



//    #if os(watchOS)
//    private func handleWorkoutEndWatchOS(date: Date) {
//        Task { @MainActor in
//            guard let builder = self.builder else {
//                print("⚠️ watchOS: No builder available for workout end")
//                return
//            }
//
//            do {
//                print("⌚ watchOS: Ending collection and finishing workout")
//                try await builder.endCollection(at: date)
//                let finishedWorkout = try await builder.finishWorkout()
//                self.workout = finishedWorkout
//                self.session?.end()
//                print("✅ watchOS: Workout finished successfully")
//            } catch {
//                print("❌ watchOS: Failed to end workout: \(error)")
//            }
//        }
//    }
//    #else
//    private func handleWorkoutEndIOS(date: Date) {
//        // iOS: Workout end is handled by the mirrored session
//        Task { @MainActor in
//            print("📱 iOS: Workout ended (handled by mirrored session)")
//            // Additional iOS-specific cleanup if needed
//        }
//    }
//    #endif
}

