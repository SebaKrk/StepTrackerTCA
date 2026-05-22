//
//  WorkoutManager+HKWorkoutSessionDelegate.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import HealthKit
import OSLog
import SharedModels

// MARK: - HKWorkoutSessionDelegate
@available(iOS 26.0, *)
extension DefaultWorkoutManager: HKWorkoutSessionDelegate {

    public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Logger.trainingManager.info("[WorkoutManager] sessionState \(fromState.description) → \(toState.description)")
        Task {
            await WorkoutFileLogger.shared.log("[Delegate] sessionState \(fromState.description) → \(toState.description)")
        }
        Task { @MainActor in
            self.workoutSessionIsRunning = toState == .running
            // Yield running / paused states immediately so TCA can react
            // (pause timer, send Watch events, etc.).
            // .stopped and .ended are yielded from consumeStateChange after
            // endCollection/finishWorkout complete.
            if toState != .stopped {
                self.workoutSessionContinuation?.yield(toState)
                Logger.trainingManager.info("[WorkoutManager] yielded state \(toState.description) to TCA stream")
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
        let nsError = error as NSError
        let domain = nsError.domain
        let code = nsError.code
        let state = workoutSession.state.description
        let description = error.localizedDescription
        Logger.trainingManager.error("[WorkoutManager] session failed — domain=\(domain), code=\(code), state=\(state), description=\(description)")
        Task {
            await WorkoutFileLogger.shared.log("[Delegate] FAILED — domain=\(domain), code=\(code), state=\(state), error=\(description)")
        }
    }
}
