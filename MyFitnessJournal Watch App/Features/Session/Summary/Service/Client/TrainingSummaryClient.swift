//
//  TrainingSummaryClient.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture
import SharedModels

struct TrainingSummaryClient {
    var setShowingSummary: @Sendable (Bool) -> Void
    var getWorkoutSummary: @Sendable () -> WorkoutSummary
    var fetchTodaySummary: @Sendable () async throws -> ActivityRingData
}

extension DependencyValues {
    var trainingSummaryClient: TrainingSummaryClient {
        get { self[TrainingSummaryClientKey.self] }
        set { self[TrainingSummaryClientKey.self] = newValue }
    }
}

private enum TrainingSummaryClientKey: DependencyKey {
    
    static let liveValue: TrainingSummaryClient = {
        
        @Dependency(\.trainingManager) var manager
        @Dependency(\.activityRingManager) var activityRingManager
        
        return TrainingSummaryClient { value in
            manager.setValueForSummaryView(value)
        } getWorkoutSummary: {
            WorkoutSummary(workout: manager.getWorkout(),
                           metrics: manager.getWorkoutMetrics()
            )
        } fetchTodaySummary: {
            try await activityRingManager.fetchTodaySummary()
        }
    }()
}
