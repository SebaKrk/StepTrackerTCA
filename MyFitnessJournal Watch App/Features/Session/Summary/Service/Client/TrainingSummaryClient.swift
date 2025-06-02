//
//  TrainingSummaryClient.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 01/06/2025.
//

import ComposableArchitecture

struct TrainingSummaryClient {
    var setShowingSummary: @Sendable (Bool) -> Void
    var getWorkoutSummary: @Sendable () -> WorkoutSummary
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
        
        return TrainingSummaryClient { value in
            manager.setValueForSummaryView(value)
        } getWorkoutSummary: {
            WorkoutSummary(workout: manager.getWorkout(),
                           metrics: manager.getWorkoutMetrics()
            )
        }
    }()
}
