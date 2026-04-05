//
//  SessionClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 28/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import HealthHub
import SharedModels

struct SessionClient {
    var selectedWorkout: @Sendable (HKWorkoutActivityType?) async throws -> Void
    var workoutMetricsStream: @Sendable () -> AsyncStream<WorkoutMetrics>
    var workoutSessionStateStream: @Sendable () -> AsyncStream<HKWorkoutSessionState>
    var elapsedTimeAt: (_ date: Date) -> TimeInterval
    var togglePause: @Sendable () async -> Void
    var getWorkoutSummary: @Sendable () async -> WorkoutSummary
    var endWorkout: @Sendable () async -> Void
    /// Adds a Watch HR sample to iPhone's HKLiveWorkoutBuilder so that
    /// the saved HKWorkout contains heart-rate data collected by Watch sensors.
    var addHeartRateSample: @Sendable (Double, Date) async -> Void

    /// Launches the Watch app so it can start its HKWorkoutSession and stream HR
    /// back to iPhone via WatchConnectivity. iPhone remains the HKWorkout owner.
    var startWatchWorkout: @Sendable (HKWorkoutActivityType) async throws -> Void
}

extension DependencyValues {
    var sessionClient: SessionClient {
        get { self[SessionClientClientKey.self] }
        set { self[SessionClientClientKey.self] = newValue }
    }
}

private enum SessionClientClientKey: DependencyKey {
    static let liveValue: SessionClient = {

        @Dependency(\.workoutManager) var manager
        @Dependency(\.trainingManager) var trainingManager

        return SessionClient { type in
            manager.setSelectedWorkout(type)
        } workoutMetricsStream: {
            manager.workoutMetricsStream
        } workoutSessionStateStream: {
            manager.workoutSessionStateStream
        } elapsedTimeAt: { date in
            manager.builder?.elapsedTime(at: date) ?? 0
        } togglePause: {
            manager.togglePause()
        } getWorkoutSummary: {
            WorkoutSummary(workout: manager.getWorkout(),
                           metrics: manager.getWorkoutMetrics())
        } endWorkout: {
            manager.endWorkout()
        } addHeartRateSample: { bpm, date in
            await manager.addHeartRateSample(bpm, at: date)
        } startWatchWorkout: { activityType in
            // iPhone is the HKWorkout owner. Watch activates, collects HR via its
            // HKWorkoutSession, and sends readings back via WatchConnectivity.
            // Watch calls discardWorkout() at end — no duplicate HKWorkout saved.
            try await trainingManager.startWatchWorkout(workoutType: activityType)
        }
    }()

}
