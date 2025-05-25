//
//  HealthKitClientKey.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/05/2025.
//
//
import ComposableArchitecture
import Factory

protocol WorkoutMetricServiceTest {
    var heartRateStream: AsyncStream<Double> { get }
    func start()
}

final class DefaultWorkoutMetricServiceTest: WorkoutMetricServiceTest {
    
    @Injected(\.workoutManagerTest) private var manager

    var heartRateStream: AsyncStream<Double> {
        manager.heartRateStream
    }

    func start() {
        manager.startWorkout()
    }

}


struct HealthKitClient {
    var heartRateStream: AsyncStream<Double>
    var start: () -> Void
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClientKey.self] }
        set { self[HealthKitClientKey.self] = newValue }
    }

    private enum HealthKitClientKey: DependencyKey {
        static let liveValue: HealthKitClient = {
            let service = Container.shared.workoutMetricServiceTest()

            return HealthKitClient(
                heartRateStream: service.heartRateStream,
                start: service.start
            )
        }()
    }
}
