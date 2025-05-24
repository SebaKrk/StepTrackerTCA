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
    func start()
    func onHeartRateUpdate(_ handler: @escaping (Double) -> Void)
}

final class DefaultWorkoutMetricServiceTest: WorkoutMetricServiceTest {
    
    @Injected(\.workoutManagerTest) private var manager
    
    private var onHeartRate: ((Double) -> Void)?

    func start() {
        manager.heartRateHandler = { [weak self] bpm in
            self?.onHeartRate?(bpm)
        }
        manager.startWorkout()
    }

    func onHeartRateUpdate(_ handler: @escaping (Double) -> Void) {
        onHeartRate = handler
    }
}


struct HealthKitClient {
    var start: (@escaping (Double) async -> Void) async -> Void
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClientKey.self] }
        set { self[HealthKitClientKey.self] = newValue }
    }

    private enum HealthKitClientKey: DependencyKey {
        static let liveValue: HealthKitClient = {
            let service = Container.shared.workoutMetricServiceTest()

            return HealthKitClient { onHeartRate in
                service.onHeartRateUpdate { bpm in
                    Task { await onHeartRate(bpm) }
                }
                service.start()
            }
        }()
    }
}
