//
//  TrainingSessionStateControl.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 31/05/2025.
//

import Foundation
import HealthKit
import OSLog
import SharedModels

// MARK: - Session State Control
extension DefaultTrainingManager {
    
    public func togglePause() {
        guard let session = session else {
            Logger.trainingManager.notice("togglePause — no active session")
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
            Logger.trainingManager.notice("endWorkout — no active session")
            return
        }
        Logger.trainingManager.info("endWorkout — calling session.end() (state=\(session.state.rawValue))")
        session.end()
    }

    // MARK: - Private Helpers

    private func pause() {
        Logger.trainingManager.info("pause — calling session.pause()")
        session?.pause()
    }

    private func resume() {
        Logger.trainingManager.info("resume — calling session.resume()")
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
                Logger.trainingManager.notice("handleWorkoutEndWatchOS — no builder")
                return
            }
            do {
                try await builder.endCollection(at: date)
                let finishedWorkout = try await builder.finishWorkout()
                self.workout = finishedWorkout
                self.session?.end()
                Logger.trainingManager.info("watchOS: workout finished and saved")
            } catch {
                Logger.trainingManager.error("watchOS: handleWorkoutEnd failed: \(error)")
            }
        }
    }
    #else
    private func handleWorkoutEndIOS(date: Date) {
        // In Watch-primary mode, Watch calls finishWorkout() which saves the HKWorkout.
        // iPhone fetches it from the shared HealthKit store after .ended fires.
        // Per Apple's WWDC23 sample, there is no push callback — we poll with retries
        // because Watch sync can take a few seconds to appear on iPhone's HealthKit.
        // First attempt is fast (1.5s); subsequent attempts every 3s (up to ~30s total).
        Task { @MainActor in
            // Clear stale workout so SummaryFeature doesn't display previous session data
            // while we poll HealthKit for the new one.
            self.workout = nil
            let startDate = self.session?.startDate ?? date.addingTimeInterval(-3600)
            let activityName = self.selectedWorkout.map { String(describing: $0) } ?? "nil"
            Logger.trainingManager.info("handleWorkoutEndIOS — polling HealthKit for Watch workout (type: \(activityName), window: \(startDate)–\(date))")

            for attempt in 1...10 {
                let delay: UInt64 = attempt == 1 ? 1_500 : 3_000
                try? await Task.sleep(for: .milliseconds(delay))
                if let hkWorkout = await self.fetchWorkoutNear(start: startDate, end: date) {
                    self.workout = hkWorkout
                    Logger.trainingManager.info("handleWorkoutEndIOS — found on attempt #\(attempt): \(hkWorkout.uuid.uuidString)")
                    return
                }
                Logger.trainingManager.notice("handleWorkoutEndIOS — attempt #\(attempt): not yet in HealthKit")
            }
            Logger.trainingManager.error("handleWorkoutEndIOS — workout NOT found after 10 attempts (~30s)")
        }
    }

    /// Queries HealthKit for a workout whose time window overlaps [start, end].
    /// Returns the most recently ended matching workout.
    ///
    /// Filters by activity type when available to avoid returning a previous
    /// workout that happens to fall in the same time window.
    private func fetchWorkoutNear(start: Date, end: Date) async -> HKWorkout? {
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end.addingTimeInterval(60))

        let predicate: NSPredicate
        if let activityType = selectedWorkout {
            let typePredicate = HKQuery.predicateForWorkouts(with: activityType)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, typePredicate])
        } else {
            predicate = datePredicate
        }

        // Sort by endDate descending — the workout that just finished should be first.
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
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
