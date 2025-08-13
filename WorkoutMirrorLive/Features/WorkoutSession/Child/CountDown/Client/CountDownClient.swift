//
//  CountDownClient.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 12/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub

public struct CountDownClient {
    var startWorkout: @Sendable () async -> Void
}

extension DependencyValues {
    var countDownClient: CountDownClient {
        get { self[WorkoutManagerClientKey.self] }
        set { self[WorkoutManagerClientKey.self] = newValue }
    }
}

private enum WorkoutManagerClientKey: DependencyKey {
    
    static let liveValue: CountDownClient = {
        
        @Dependency(\.workoutManager) var manager
        
        return CountDownClient {
            await manager.startWorkout()
        }
    }()
    
}
