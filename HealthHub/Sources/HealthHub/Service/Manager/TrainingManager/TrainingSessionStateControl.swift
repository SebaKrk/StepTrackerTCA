//
//  TrainingSessionStateControl.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit

// MARK: - Session State Control
extension DefaultTrainingManager {
    
    public func togglePause() {
        guard let session = session else {
            print("⚠️ [TrainingManager] togglePause — no active session")
            return
        }
        if workoutSessionIsRunning {
            pause()
        } else {
            resume()
        }
    }

    public func endWorkout() {
        guard let session = session else {
            print("⚠️ [TrainingManager] endWorkout — no active session")
            return
        }
        print("🔚 [TrainingManager] endWorkout — calling session.end() (state=\(session.state.rawValue))")
        session.end()
    }

    // MARK: - Private Helpers

    private func pause() {
        print("⏸️ [TrainingManager] pause — calling session.pause()")
        session?.pause()
    }

    private func resume() {
        print("▶️ [TrainingManager] resume — calling session.resume()")
        session?.resume()
    }
    
    // MARK: - Platform-specific Workout End Handling
    
    internal func handleWorkoutEnd(date: Date) {
        #if os(watchOS)
        handleWorkoutEndWatchOS(date: date)
        #else
        handleWorkoutEndIOS(date: date)
        #endif
    }
    
    #if os(watchOS)
    private func handleWorkoutEndWatchOS(date: Date) {
        Task { @MainActor in
            guard let builder = self.builder else {
                print("⚠️ [TrainingManager] handleWorkoutEndWatchOS — no builder")
                return
            }
            do {
                try await builder.endCollection(at: date)
                let finishedWorkout = try await builder.finishWorkout()
                self.workout = finishedWorkout
                self.session?.end()
                print("✅ [TrainingManager] watchOS: workout finished and saved")
            } catch {
                print("❌ [TrainingManager] watchOS: handleWorkoutEnd failed: \(error)")
            }
        }
    }
    #else
    private func handleWorkoutEndIOS(date: Date) {
        // In Watch-primary mode, Watch calls finishWorkout() which saves the HKWorkout.
        // iPhone needs to fetch it from HealthKit after a short delay to allow Watch
        // to complete the save before we query.
        Task { @MainActor in
            let startDate = self.session?.startDate ?? date.addingTimeInterval(-3600)
            print("📱 [TrainingManager] handleWorkoutEndIOS — session ended, waiting 2s for Watch to save workout")
            try? await Task.sleep(for: .milliseconds(2000))
            if let hkWorkout = await self.fetchWorkoutNear(start: startDate, end: date) {
                self.workout = hkWorkout
                print("✅ [TrainingManager] handleWorkoutEndIOS — workout fetched: \(hkWorkout.uuid)")
            } else {
                print("⚠️ [TrainingManager] handleWorkoutEndIOS — workout NOT found in HealthKit (Watch may not have saved yet)")
            }
        }
    }

    /// Queries HealthKit for a workout whose time window overlaps [start, end].
    /// Returns the most recently created matching workout.
    private func fetchWorkoutNear(start: Date, end: Date) async -> HKWorkout? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end.addingTimeInterval(30))
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                continuation.resume(returning: samples?.first as? HKWorkout)
            }
            healthStore.execute(query)
        }
    }
    #endif
}
