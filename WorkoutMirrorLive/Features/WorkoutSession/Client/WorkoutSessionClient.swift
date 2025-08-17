//
//  WorkoutSessionClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import Foundation
import ComposableArchitecture
import HealthKit
import SharedModels
import HealthHub

struct WorkoutSessionClient {
    var selectedWorkout: @Sendable (HKWorkoutActivityType?) async throws -> Void
    var workoutMetricsStream: @Sendable () -> AsyncStream<WorkoutMetrics>
    var workoutSessionIsRunningStream: @Sendable () -> AsyncStream<Bool>
    var elapsedTimeAt: (_ date: Date) -> TimeInterval
    var togglePause: @Sendable () async -> Void
    var endWorkout: @Sendable () async -> Void
}

extension DependencyValues {
    var workoutSessionClient: WorkoutSessionClient {
        get { self[WorkoutSessionClientClientKey.self] }
        set { self[WorkoutSessionClientClientKey.self] = newValue }
    }
}

private enum WorkoutSessionClientClientKey: DependencyKey {
    static let liveValue: WorkoutSessionClient = {
        
        @Dependency(\.workoutManager) var manager
   
        return WorkoutSessionClient { type in
            manager.setSelectedWorkout(type)
        } workoutMetricsStream: {
            manager.workoutMetricsStream
        } workoutSessionIsRunningStream: {
            manager.workoutSessionIsRunningStream()
        } elapsedTimeAt: { date in
            manager.builder?.elapsedTime(at: date) ?? 0
        } togglePause: {
            manager.togglePause()
        } endWorkout: {
            manager.endWorkout()
        }
    }()
}
