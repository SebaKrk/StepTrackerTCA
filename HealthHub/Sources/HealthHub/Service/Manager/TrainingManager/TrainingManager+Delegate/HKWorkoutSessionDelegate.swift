//
//  HKWorkoutSessionDelegate.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
import SharedModels

// MARK: - HKWorkoutSessionDelegate (Both Platforms)
extension DefaultTrainingManager: HKWorkoutSessionDelegate {
    
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didChangeTo toState: HKWorkoutSessionState,
                               from fromState: HKWorkoutSessionState,
                               date: Date) {
        
        print("💫 Session state changed from \(fromState.rawValue) to \(toState.rawValue)")
        
        Task { @MainActor in
            self.workoutSessionIsRunning = toState == .running
            self.workoutSessionContinuation?.yield(self.workoutSessionIsRunning)
            
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
        print("❌ Workout session failed with error: \(error)")
    }
    
    // MARK: - iOS-specific Delegate Methods
    
#if os(iOS)
    /// iOS-specific: Handle data received from Apple Watch
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        print("📱 iOS: Received \(data.count) data objects from Watch")
        
        Task { @MainActor in
            do {
                for dataElement in data {
                    try processReceivedWatchData(dataElement) 
                }
            } catch {
                print("❌ iOS: Failed to handle received data: \(error)")
            }
        }
    }
    
    /// iOS-specific: Handle disconnection from Apple Watch
    public func workoutSession(_ workoutSession: HKWorkoutSession,
                               didDisconnectFromRemoteDeviceWithError error: Error?) {
        print("📱 iOS: Disconnected from Watch: \(error?.localizedDescription ?? "No error")")
        
        Task { @MainActor in
            self.workoutSessionIsRunning = false
            self.workoutSessionContinuation?.yield(false)
        }
    }
#endif
    
    // MARK: - Helper Methods

#if os(watchOS)
    private func sendElapsedTimeToCompanion(date: Date) async {
        print("🔄 sendElapsedTimeToCompanion called")
        
        guard let session = self.session else {
            print("⚠️ No session in sendElapsedTimeToCompanion")
            return
        }
        
        let elapsedTimeInterval = session.associatedWorkoutBuilder().elapsedTime(at: date)
        let elapsedTime = WorkoutElapsedTime(timeInterval: elapsedTimeInterval, date: date)
        
        if let elapsedTimeData = try? JSONEncoder().encode(elapsedTime) {
            print("🔄 About to call sendData with elapsed time: \(elapsedTimeInterval)s")
            await sendData(elapsedTimeData)
            print("⌚ watchOS: Sent elapsed time to iOS: \(elapsedTimeInterval)s")
        } else {
            print("❌ Failed to encode elapsed time")
        }
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
            self.workoutMetricsContinuation?.yield(receivedMetrics)
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
