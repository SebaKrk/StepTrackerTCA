//
//  HeartRateClientKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/05/2025.
//

import ComposableArchitecture

struct HeartRateClient {
    var heartRateStream: AsyncStream<Double>
    var start: () -> Void
}

extension DependencyValues {
    var heartRateClient: HeartRateClient {
        get { self[HeartRateClientKey.self] }
        set { self[HeartRateClientKey.self] = newValue }
    }
}

private enum HeartRateClientKey: DependencyKey {
    static let liveValue: HeartRateClient = {
        
        @Dependency(\.workoutManagerTest) var manager
        
        return HeartRateClient(
            heartRateStream: manager.heartRateStream,
            start: manager.startWorkout
        )
    }()
}
