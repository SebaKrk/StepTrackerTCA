//
//  TrainingSessionClient.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 28/05/2025.
//

import Foundation
import ComposableArchitecture
import HealthKit

struct TrainingSessionClient {
    var selectedWorkout: @Sendable (HKWorkoutActivityType?) async throws -> Void
    var workoutMetricsStream: @Sendable () -> AsyncStream<WorkoutMetrics>
    var workoutSessionIsRunningStream: @Sendable () -> AsyncStream<Bool>
    var elapsedTimeAt: (_ date: Date) -> TimeInterval
    var togglePause: @Sendable () async -> Void
    var endWorkout: @Sendable () async -> Void
}

extension DependencyValues {
    var trainingSessionClient: TrainingSessionClient {
        get { self[TrainingSessionClientKey.self] }
        set { self[TrainingSessionClientKey.self] = newValue }
    }
}

private enum TrainingSessionClientKey: DependencyKey {
    static let liveValue: TrainingSessionClient = {
        
        @Dependency(\.trainingManager) var manager
   
        return TrainingSessionClient { type in
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
