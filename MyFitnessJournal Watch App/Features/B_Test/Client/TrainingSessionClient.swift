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
    var setShowingSummary: @Sendable (Bool) -> Void
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
        } setShowingSummary: { value in
            manager.setValueForSumaryView(value)
        }
    }()

}

//extension DependencyValues {
//    var heartRateClient: HeartRateClient {
//        get { self[HeartRateClientKey.self] }
//        set { self[HeartRateClientKey.self] = newValue }
//    }
//}
//
//private enum HeartRateClientKey: DependencyKey {
//    static let liveValue: HeartRateClient = {
//        
//        @Dependency(\.workoutManagerTest) var manager
//        
//        return HeartRateClient(
//            heartRateStream: manager.heartRateStream,
//            start: manager.startWorkout
//        )
//    }()
//}

//extension TrainingSessionClient {
//    static let live = TrainingSessionClient(
//        selectedWorkout: nil,
//        workoutMetricsStream: {
//            workoutManager.workoutMetricsStream
//        },
//        workoutSessionIsRunning: {
//            workoutManager.workoutSessionIsRunning
//        },
//        togglePause: {
//            await workoutManager.togglePause()
//        }
//    )
//}
