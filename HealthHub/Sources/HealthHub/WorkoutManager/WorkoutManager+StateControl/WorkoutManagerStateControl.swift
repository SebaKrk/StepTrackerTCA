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

        // stopActivity triggers didChangeTo(.stopped) in the delegate,
        // which enqueues the state in stateChangeTuple. The FIFO consumer
        // (consumeStateChange) then calls endCollection → finishWorkout → session.end().
        sessionState = .stopped
        session.stopActivity(with: .now)
    }

    // MARK: - Private Helpers

    private func pause(_ session: HKWorkoutSession) {
        session.pause()
    }

    private func resume(_ session: HKWorkoutSession) {
        session.resume()
    }
}
