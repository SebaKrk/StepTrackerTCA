//
//  WorkoutSummaryClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 14/08/2025.
//

import ComposableArchitecture
import SharedModels
import HealthHub
import HealthKit

struct WorkoutSummaryClient {
    //var setShowingSummary: @Sendable (Bool) -> Void
//    var getWorkoutSummary: @Sendable () async -> WorkoutSummary
    var getWorkoutSummary: @Sendable () async -> WorkoutSummary
    //var sessionStateStream: @Sendable () -> AsyncStream<HKWorkoutSessionState>
    //var fetchTodaySummary: @Sendable () async throws -> ActivityRingData
}

extension DependencyValues {
    var workoutSummaryClient: WorkoutSummaryClient {
        get { self[WorkoutSummaryClientKey.self] }
        set { self[WorkoutSummaryClientKey.self] = newValue }
    }
}

private enum WorkoutSummaryClientKey: DependencyKey {
    
    static let liveValue: WorkoutSummaryClient = {
        @Dependency(\.workoutManager) var manager
        
        return WorkoutSummaryClient {
            WorkoutSummary(workout: manager.getWorkout(),
                           metrics: manager.getWorkoutMetrics())
            //            WorkoutSummary(
            //                workout: manager.getWorkout(),
            //                metrics: manager.getWorkoutMetrics()
            //            )
            //        } sessionStateStream: {
            //            manager.sessionStateStream()
            //        }
        }
    }()
    
}

    //2
//                WorkoutSummary(workout: manager.getWorkout(),
//                               metrics: manager.getWorkoutMetrics())
    
// 1
//    static let liveValue: TrainingSummaryClient = {
//        
//        @Dependency(\.trainingManager) var manager
//        @Dependency(\.activityRingManager) var activityRingManager
//        
//        return TrainingSummaryClient { value in
//            manager.setValueForSummaryView(value)
//        } getWorkoutSummary: {
//            WorkoutSummary(workout: manager.getWorkout(),
//                           metrics: manager.getWorkoutMetrics()
//            )
//        } fetchTodaySummary: {
//            try await activityRingManager.fetchTodaySummary()
//        }
//    }()
//}

