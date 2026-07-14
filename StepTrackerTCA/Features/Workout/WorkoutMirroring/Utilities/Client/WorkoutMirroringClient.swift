//
//  WorkoutMirroringClient.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

struct WorkoutMirroringClient {
    var workoutMetricsStream: @Sendable () -> AsyncStream<WorkoutMetrics>
    var sessionState: @Sendable () -> Bool
}

extension DependencyValues {
    var workoutMirroringClient: WorkoutMirroringClient {
        get { self[WorkoutMirroringClientKey.self] }
        set { self[WorkoutMirroringClientKey.self] = newValue }
    }
}

private enum WorkoutMirroringClientKey: DependencyKey {
    static let liveValue: WorkoutMirroringClient = {
        
        @Dependency(\.trainingManager) var manager
        
        return WorkoutMirroringClient(
            workoutMetricsStream: {
                manager.workoutMetricsStream
            },
            sessionState: {
                manager.sessionState.isActive
            }
        )
    }()
    
}
