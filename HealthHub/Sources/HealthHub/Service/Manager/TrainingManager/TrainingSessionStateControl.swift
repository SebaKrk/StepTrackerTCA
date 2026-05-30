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
        // Push-based AsyncSequence via `HKAnchoredObjectQueryDescriptor.results(for:)`.
        // Replaces the previous polling loop (up to ~30s timeout). The descriptor registers
        // an HK change observer — when Watch's saved HKWorkout syncs to iPhone's HealthKit
        // store (~1-2s typically), it emits with `addedSamples`. No polling.
        Task { @MainActor in
            self.workout = nil
            let startDate = self.session?.startDate ?? date.addingTimeInterval(-3600)
            let activityName = self.selectedWorkout.map { String(describing: $0) } ?? "nil"
            Logger.trainingManager.info("handleWorkoutEndIOS — observing HealthKit for Watch workout (type: \(activityName), window: \(startDate)–\(date))")

            let datePredicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: date.addingTimeInterval(60)
            )
            let predicate: NSPredicate
            if let activityType = selectedWorkout {
                let typePredicate = HKQuery.predicateForWorkouts(with: activityType)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, typePredicate])
            } else {
                predicate = datePredicate
            }

            let descriptor = HKAnchoredObjectQueryDescriptor(
                predicates: [.workout(predicate)],
                anchor: nil
            )

            do {
                for try await result in descriptor.results(for: self.healthStore) {
                    if let workout = result.addedSamples.first {
                        self.workout = workout
                        Logger.trainingManager.info("handleWorkoutEndIOS — observed: \(workout.uuid.uuidString)")
                        return
                    }
                }
            } catch {
                Logger.trainingManager.error("handleWorkoutEndIOS — anchored query failed: \(error.localizedDescription)")
            }
        }
    }
    #endif
}
