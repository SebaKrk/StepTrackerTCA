//
//  WorkoutManager+HKWorkoutSessionDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import HealthKit

// MARK: - HKWorkoutSessionDelegate
@available(iOS 26.0, *)
extension DefaultWorkoutManager: HKWorkoutSessionDelegate {

    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        print("🔄 [DefaultWorkoutManager] sessionState: \(fromState.rawValue) → \(toState.rawValue)")
        Task { @MainActor in
            self.workoutSessionIsRunning = toState == .running
            // Yield running / paused states immediately so TCA can react
            // (pause timer, send Watch events, etc.).
            // .stopped and .ended are yielded from consumeStateChange after
            // endCollection/finishWorkout complete.
            if toState != .stopped {
                self.workoutSessionContinuation?.yield(toState)
                print("📡 [DefaultWorkoutManager] yielded state \(toState.rawValue) to TCA stream")
            }
        }

        // Enqueue for FIFO processing. consumeStateChange handles the
        // .stopped case by calling endCollection → finishWorkout → session.end().
        stateChangeTuple.continuation.yield((toState, date))
    }

    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("❌ Workout session failed with error: \(error)")
    }
}
