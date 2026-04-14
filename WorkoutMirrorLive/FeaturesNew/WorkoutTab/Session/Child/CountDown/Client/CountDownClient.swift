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
        // Route through SessionClient so Watch-primary mode is a no-op.
        // Previously used workoutManager directly — that caused
        // DefaultWorkoutManager.startWorkout() to fail in Watch-primary mode
        // because iPhone has no prepared HKWorkoutSession in that mode.
        @Dependency(\.sessionClient) var sessionClient

        return CountDownClient {
            await sessionClient.startWorkout()
        }
    }()

}
