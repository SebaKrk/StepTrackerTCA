//
//  SessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels
import HealthKit

@Reducer
struct SessionFeature {
    
    // MARK: - Dependency

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.personCalculatorClient) var calculator
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.continuousClock) var clock

    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
            case let .sessionViewStateChange(value):
                state.sessionState = value
                if value == .session {
                    let initialState = WorkoutSessionActivityAttributes.ContentState(
                        heartRate: 0,
                        heartRateZone: .resting,
                        heartRatePercentage: 0,
                        activeEnergy:  0,
                        maxHeartRate: 0,
                        averageHeartRate: 0
                    )

                    let phases = state.trainingSession?.phases ?? []

                    return .merge(
                        .run { send in
                            for await state in await self.sessionClient.workoutSessionStateStream() {
                                await send(.controls(.sessionStateUpdated(state)))
                            }
                        }
                        .cancellable(id: SessionWatchCancelID.sessionStateStream),
                        // iPhone-side metrics (calories, HR from BT sensor if present).
                        .run { send in
                            for await metrics in self.sessionClient.workoutMetricsStream() {
                                print("📊 [SessionFeature] iPhoneMetrics — HR: \(metrics.heartRate), energy: \(metrics.activeEnergy)")
                                await send(.live(.workoutMetrics(metrics)))
                            }
                        }
                        .cancellable(id: SessionWatchCancelID.metricsStream),
                        .send(.live(.liveActivity(.workout(.start(workoutName: state.selectedWorkout.title, initialState: initialState))))),
                        .send(.live(.setupPhasePanel(phases))),
                        .run { [maxHR = state.live.maxHeartRate, activityTypeRaw = state.selectedWorkout.hkType.rawValue, watchClient = watchConnectivityClient] send in
                            print("⌚️ [SessionFeature] Sending workoutStarted to Watch — activityType: \(activityTypeRaw), maxHR: \(maxHR)")
                            await watchClient.sendWorkoutEvent(
                                .workoutStarted(activityType: activityTypeRaw, elapsedSeconds: 0, maxHeartRate: maxHR)
                            )
                            // countdownFinished sent immediately after — Watch uses this as the
                            // signal to start its elapsed-time timer instead of running its own
                            // countdown, eliminating WatchConnectivity drift.
                            await watchClient.sendWorkoutEvent(.countdownFinished)
                        },
                        .run { [watchClient = watchConnectivityClient] send in
                            for await event in watchClient.incomingEventStream() {
                                await send(.watchEventReceived(event))
                            }
                        }
                        .cancellable(id: SessionWatchCancelID.watchEventStream),
                        .run { [clock = clock] send in
                            for await _ in clock.timer(interval: .seconds(1)) {
                                await send(.watchTickEffect)
                            }
                        }
                        .cancellable(id: SessionWatchCancelID.watchTickTimer)
                    )
                } else if value == .summary {
                    return .merge(
                        .cancel(id: SessionWatchCancelID.sessionStateStream),
                        .cancel(id: SessionWatchCancelID.watchEventStream),
                        .cancel(id: SessionWatchCancelID.watchTickTimer),
                        .cancel(id: SessionWatchCancelID.metricsStream),
                        .send(.live(.liveActivity(.workout(.stop)))),
                        .send(.live(.liveActivity(.timer(.stop))))
                    )
                }
                return .none

            case .makeCalculationForSession:
                return .run { send in
                    let age = try await personalDataClient.getAge()
                    let sex = try await personalDataClient.getBiologicalSex()
                    
                    guard let age = age, let sex = sex else {
                        return
                    }
                    
                    let maxHR = await calculator.calculateMaxHeartRate(age, sex)
                    await send(.setMaxHR(maxHR))
                }
                
            case let .setMaxHR(value):
                let isSessionActive = state.sessionState == .session
                return .merge(
                    .send(.live(.setupMaxHeartRate(value))),
                    isSessionActive ? .run { [watchClient = watchConnectivityClient] send in
                        await watchClient.sendWorkoutEvent(.maxHRUpdated(value))
                    } : .none
                )
                            
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { [workout = state.selectedWorkout, trainingSession = state.trainingSession, watchClient = watchConnectivityClient] send in
                    await watchClient.initializeWatchConnectivity()
                    let watchStatus = await watchClient.checkWatchStatus()
                    print("🏋️ [SessionFeature] viewDidAppear — watchStatus: \(watchStatus.rawValue), workout: \(workout.title)")

                    // Always prepare iPhone session — CountDownClient.startWorkout() requires it.
                    try await self.sessionClient.selectedWorkout(workout.hkType)
                    print("✅ [SessionFeature] selectedWorkout set → DefaultWorkoutManager.prepareWorkout() triggered")

                    if watchStatus == .ready {
                        // Additionally launch Watch app so Watch can start its own HKWorkoutSession
                        // and stream HR readings back via WatchConnectivity.
                        print("⌚️ [SessionFeature] Watch is ready → launching Watch workout")
                        try? await self.sessionClient.startWatchWorkout(workout.hkType)
                    } else {
                        print("📱 [SessionFeature] Watch unavailable (\(watchStatus.rawValue)) → iPhone-primary path, HKLiveWorkoutDataSource active")
                    }

                    await send(.controls(.setWorkoutType(workout)))
                    await send(.makeCalculationForSession)
                    await send(.summary(.setTrainingSession(trainingSession)))
                }
 
            case .view(.heartRateZoneButtonTapped):
                state.destination = .openHeartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none
                
            case .view(.timerButtonTapped):
                // Forward to LiveSessionFeature
                return .send(.live(.userStopwatch(.view(.toggleVisibility))))

                // MARK: - Destination
            case .destination(_):
                return .none
                
                // MARK: - Child
            case .countDown(.closeView):
                return .send(.sessionViewStateChange(.session))
                
            case .watchTickEffect:
                let elapsed = state.controls.elapsedTime
                return .run { [elapsed] send in
                    await self.watchConnectivityClient.sendWorkoutEvent(.workoutTick(elapsedSeconds: elapsed))
                }

            case .controls(.sessionStateUpdated(.paused)):
                return .merge(
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    .run { send in
                        await self.watchConnectivityClient.sendWorkoutEvent(.workoutPaused)
                    }
                )

            case .controls(.sessionStateUpdated(.running)):
                guard state.controls.sessionState == .paused else { return .none }
                let elapsed = state.controls.elapsedTime
                return .merge(
                    .run { [elapsed] send in
                        await self.watchConnectivityClient.sendWorkoutEvent(.workoutResumed(elapsedSeconds: elapsed))
                    },
                    .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.watchTickEffect)
                        }
                    }
                    .cancellable(id: SessionWatchCancelID.watchTickTimer, cancelInFlight: true)
                )

            case .controls(.view(.endWorkoutButtonTapped)):
                return .merge(
                    .cancel(id: SessionWatchCancelID.watchEventStream),
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    .run { send in
                        await self.watchConnectivityClient.sendWorkoutEvent(.workoutEnded)
                        await send(.sessionViewStateChange(.summary))
                    }
                )

            case .watchEventReceived(.hrReading(let bpm, let timestamp)):
                print("❤️ [SessionFeature] hrReading received from Watch — \(Int(bpm)) bpm")
                let current = state.live.workoutMetrics
                return .merge(
                    // Update display metrics.
                    .send(.live(.workoutMetrics(
                        WorkoutMetrics(
                            averageHeartRate: current.averageHeartRate,
                            heartRate: bpm,
                            activeEnergy: current.activeEnergy
                        )
                    ))),
                    // Persist Watch HR in iPhone's HKLiveWorkoutBuilder so the saved
                    // HKWorkout contains heart-rate data from Watch sensors.
                    .run { [bpm, timestamp] _ in
                        await self.sessionClient.addHeartRateSample(bpm, timestamp)
                    }
                )

            case .watchEventReceived(.workoutPaused):
                guard state.controls.sessionState == .running else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .watchEventReceived(.workoutResumed):
                guard state.controls.sessionState == .paused else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .watchEventReceived:
                return .none

            case .summary(.view(.endWorkoutButtonTapped)):
                return .none
                
            case .countDown(_):
                return .none
            case .live(_):
                return .none
            case .controls(_):
                return .none
            case .summary(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.live, action: \.live) {
            LiveSessionFeature()
        }
        Scope(state: \.controls, action: \.controls) {
            ControlsFeature()
        }
        Scope(state: \.summary, action: \.summary) {
            SummaryFeature()
        }
    }
}

// MARK: - Cancel IDs

/// Cancel identifiers used by `SessionFeature` long-running effects.
///
/// Declared outside the `@Reducer` to avoid `@MainActor` isolation
/// that would prevent conformance to `Sendable` (required by `cancellable(id:)`).
private nonisolated enum SessionWatchCancelID: Hashable, Sendable {

    /// Identifies the HKWorkoutSessionState stream from DefaultWorkoutManager.
    case sessionStateStream

    /// Identifies the stream listening for incoming Watch workout events.
    case watchEventStream

    /// Identifies the one-second clock effect that sends `workoutTick` to Watch.
    case watchTickTimer

    /// Identifies the iPhone-side HKLiveWorkoutBuilder metrics stream.
    case metricsStream

}
