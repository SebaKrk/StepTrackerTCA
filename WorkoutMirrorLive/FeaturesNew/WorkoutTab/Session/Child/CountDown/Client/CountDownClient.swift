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
        get { self[CountDownClientKey.self] }
        set { self[CountDownClientKey.self] = newValue }
    }
}

private enum CountDownClientKey: DependencyKey {

    static let liveValue: CountDownClient = {
        // Route through SessionClient so Watch-primary mode is a no-op
        // (iPhone has no prepared HKWorkoutSession in Watch-primary mode).
        @Dependency(\.sessionClient) var sessionClient

        return CountDownClient {
            await sessionClient.startWorkout()
        }
    }()

}
