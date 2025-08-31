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
        }
    }()
    
}
