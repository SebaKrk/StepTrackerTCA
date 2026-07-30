//
//  HKWorkoutSessionDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
import OSLog
import SharedModels

// MARK: - HKWorkoutSessionDelegate (Both Platforms)
extension DefaultTrainingManager: HKWorkoutSessionDelegate {
    
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didChangeTo toState: HKWorkoutSessionState,
                               from fromState: HKWorkoutSessionState,
                               date: Date) {
        guard isCurrentSession(workoutSession, callback: "didChangeTo \(toState.rawValue)") else { return }

        Logger.trainingManager.info("sessionState \(fromState.rawValue) → \(toState.rawValue)")
        
        Task { @MainActor in
            self.workoutSessionIsRunning = toState == .running
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
            self.workoutSessionStateContinuation?.yield(toState)

#if os(watchOS)
            // watchOS: Send elapsed time to iOS
            await sendElapsedTimeToCompanion(date: date)
#endif
        }
        
        // Handle workout end using the method from TrainingSessionStateControl
        if toState == .ended {
            handleWorkoutEnd(date: date)
        }
    }
    
    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        guard isCurrentSession(workoutSession, callback: "didFailWithError") else { return }
        Logger.trainingManager.error("workoutSession failed: \(error.localizedDescription)")
    }
    
    // MARK: - iOS-specific Delegate Methods
    
#if os(iOS)
    /// iOS-specific: Handle data received from Apple Watch
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        guard isCurrentSession(workoutSession, callback: "didReceiveData") else { return }
        let totalBytes = data.reduce(0) { $0 + $1.count }
        Logger.trainingManager.info("didReceiveDataFromRemoteWorkoutSession — \(data.count) object(s), \(totalBytes) bytes")

        Task { @MainActor in
            do {
                for dataElement in data {
                    try processReceivedWatchData(dataElement)
                }
            } catch {
                Logger.trainingManager.error("processReceivedWatchData failed: \(error.localizedDescription)")
            }
        }
    }

    /// iOS-specific: Handle disconnection from Apple Watch
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didDisconnectFromRemoteDeviceWithError error: Error?) {
        guard isCurrentSession(workoutSession, callback: "didDisconnect") else { return }
        let state = workoutSession.state.description
        let errorDescription = error?.localizedDescription ?? "no error"
        Logger.trainingManager.notice("disconnected from Watch: \(errorDescription), state=\(state)")
        Task {
            await WorkoutFileLogger.shared.log("[Disconnect] mirrored session — state=\(state), error=\(errorDescription)")
        }

        Task { @MainActor in
            // Disconnect ≠ stopped (IOS-00098-G). The old `.stopped` yield here made the
            // UI fake a workout end while the Watch kept measuring. A dead link is a
            // separate signal — the primary session may still be running and the system
            // auto-reconnects (start handler will deliver a fresh mirrored session).
            //
            // Mirroring also disconnects on a NORMAL end (logs: "state=ended, no error")
            // — that teardown must not raise a connection-lost banner.
            guard workoutSession.state == .running || workoutSession.state == .paused else {
                Logger.trainingManager.info("didDisconnect during teardown (state=\(state)) — not a link loss")
                return
            }
            self.yieldWatchConnectionStatus(.lost)
        }
    }
#endif
    
    // MARK: - Helper Methods

    /// Identity guard against stale-session callbacks.
    ///
    /// After a mirroring reconnect, `workoutSessionMirroringStartHandler` replaces
    /// `self.session` with a fresh instance, but the abandoned one can still fire
    /// delegate callbacks — without this guard they would mutate state belonging
    /// to the new session (e.g. a late `didDisconnect` yielding `.stopped` right
    /// after a successful reconnect).
    private func isCurrentSession(_ workoutSession: HKWorkoutSession, callback: String) -> Bool {
        guard workoutSession === session else {
            Logger.trainingManager.notice("ignoring \(callback) from stale session (state=\(workoutSession.state.rawValue))")
            return false
        }
        return true
    }

#if os(watchOS)
    private func sendElapsedTimeToCompanion(date: Date) async {
        guard let session = self.session else {
            Logger.trainingManager.error("sendElapsedTimeToCompanion — no session")
            return
        }
        let elapsedTimeInterval = session.associatedWorkoutBuilder().elapsedTime(at: date)
        let elapsedTime = WorkoutElapsedTime(timeInterval: elapsedTimeInterval, date: date)
        guard let elapsedTimeData = try? JSONEncoder().encode(elapsedTime) else {
            Logger.trainingManager.error("sendElapsedTimeToCompanion — encode failed")
            return
        }
        await sendData(elapsedTimeData)
    }
#endif
    
#if os(iOS)
    private func handleReceivedDataFromWatch(_ data: Data) throws {
        print("📱 iOS: Processing received data of size: \(data.count) bytes")
        
        // Try to decode as WorkoutElapsedTime (for time synchronization)
        if let elapsedTime = try? JSONDecoder().decode(WorkoutElapsedTime.self, from: data) {
            var currentElapsedTime: TimeInterval = 0
            if session?.state == .running {
                currentElapsedTime = elapsedTime.timeInterval + Date().timeIntervalSince(elapsedTime.date)
            } else {
                currentElapsedTime = elapsedTime.timeInterval
            }
            print("📱 iOS: Updated elapsed time: \(currentElapsedTime)")
            // TODO: Update your elapsed time property here if you have one
            return
        }
        
        // Try to decode as WorkoutMetrics (custom JSON format)
        if let receivedMetrics = try? JSONDecoder().decode(WorkoutMetrics.self, from: data) {
            print("📱 iOS: Received WorkoutMetrics - HR: \(receivedMetrics.heartRate), Energy: \(receivedMetrics.activeEnergy)")
            self.metrics = receivedMetrics
            yieldWorkoutMetrics(receivedMetrics)
            return
        }
        
        // Try to decode as HKStatistics array (standard HealthKit data from watchOS)
        if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: HKStatistics.self, from: data) {
            print("📱 iOS: Received \(statisticsArray.count) HKStatistics objects")
            for statistics in statisticsArray {
                updateForStatistics(statistics)
            }
            return
        }
        
        print("⚠️ iOS: Received unrecognized data format")
    }
#endif
}

// MARK: - Supporting Types
struct WorkoutElapsedTime: Codable {
    var timeInterval: TimeInterval
    var date: Date
}
