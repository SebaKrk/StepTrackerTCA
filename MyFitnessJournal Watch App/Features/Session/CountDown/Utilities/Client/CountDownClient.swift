//
//  CountDownClient.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 20/06/2025.
//

import ComposableArchitecture
import Foundation

public struct CountDownClient {
    var startWorkout: @Sendable () async -> Void
}

extension DependencyValues {
    var countDownClient: CountDownClient {
        get { self[TrainingSessionClientKey.self] }
        set { self[TrainingSessionClientKey.self] = newValue }
    }
}

private enum TrainingSessionClientKey: DependencyKey {
    
    static let liveValue: CountDownClient = {
        
        @Dependency(\.trainingManager) var manager
        
        return CountDownClient {
            await manager.startWorkout()
        }
    }()
    
}
