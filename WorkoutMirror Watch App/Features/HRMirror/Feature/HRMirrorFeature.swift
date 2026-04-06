//
//  HRMirrorFeature.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

/// Reducer for the HR Mirror screen on Apple Watch.
///
/// The Watch acts as the **primary workout actor** — it owns a `HKWorkoutSession`
/// and mirrors it to the paired iPhone via `startMirroringToCompanionDevice()`.
/// The iPhone receives a mirrored session and displays data; the Watch is
/// the source of truth for HealthKit recording.
///
/// Data flow:
/// 1. `WatchWorkoutSessionClient` starts `HKWorkoutSession` + mirroring on `.start`.
/// 2. `HKLiveWorkoutBuilder` yields live BPM readings, forwarded to iPhone as `.hrReading`.
/// 3. iPhone sends elapsed-time ticks (`workoutTick`) — Watch uses them as source of truth.
/// 4. On `.stop`, the session is properly ended before the feature scope is torn down.
@Reducer
struct HRMirrorFeature {

    // MARK: - Dependencies

    @Dependency(\.watchWorkoutSessionClient) var watchWorkoutSessionClient
    @Dependency(\.watchConnectivityClientAW) var watchClient
    @Dependency(\.extendedRuntimeClient) var extendedRuntimeClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Internal Actions

            case .hrReceived(let bpm):
                state.isPreparing = false
                state.heartRate = Int(bpm)
                state.heartRateZone = heartRateZone(bpm: Int(bpm), max: state.maxHeartRate)
                return .run { [watchClient = watchClient] send in
                    await watchClient.sendWorkoutEvent(.hrReading(bpm: bpm, timestamp: Date()))
                }

            case .subSecondTick:
                guard !state.isPaused else { return .none }
                state.elapsedSeconds += 0.1
                return .none

            // MARK: - iPhone Events

            case .workoutPaused:
                state.isPaused = true
                return .cancel(id: HRMirrorCancelID.subSecondTimer)

            case .workoutResumed(let elapsed):
                state.elapsedSeconds = elapsed
                state.isPaused = false
                return .run { [clock] send in
                    for await _ in clock.timer(interval: .milliseconds(100)) {
                        await send(.subSecondTick)
                    }
                }
                .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)

            case .workoutTick(let elapsed):
                // iPhone is source of truth — reset to exact value each second.
                state.elapsedSeconds = elapsed
                return .none

            // MARK: - View Actions

            case .view(.pauseResumeTapped):
                if state.isPaused {
                    state.isPaused = false
                    let elapsed = state.elapsedSeconds
                    return .run { [elapsed, watchClient = watchClient] send in
                        await watchClient.sendWorkoutEvent(.workoutResumed(elapsedSeconds: elapsed))
                    }
                } else {
                    state.isPaused = true
                    return .run { [watchClient = watchClient] send in
                        await watchClient.sendWorkoutEvent(.workoutPaused)
                    }
                }

            case .hideTabIndicator:
                state.showTabIndicator = false
                return .none

            case .view(.screenTapped):
                state.showTabIndicator = true
                return .run { send in
                    try? await Task.sleep(for: .seconds(3))
                    await send(.hideTabIndicator)
                }
                .cancellable(id: HRMirrorCancelID.tabIndicatorTimer, cancelInFlight: true)

            case .view(.tabSelected(let tab)):
                state.selectedTab = tab
                return .none

            // MARK: - Lifecycle

            case .start:
                let activityType = state.activityType
                return .merge(
                    .run { [extendedRuntimeClient = extendedRuntimeClient] send in
                        await extendedRuntimeClient.start()
                    },
                    // Start HealthKit session immediately — HR readings accumulate
                    // while iPhone finishes its countdown.
                    .run { [watchWorkoutSessionClient = watchWorkoutSessionClient, activityType] send in
                        for await bpm in await watchWorkoutSessionClient.startSession(activityType) {
                            await send(.hrReceived(bpm))
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.hrQuery),
                    .run { send in
                        try? await Task.sleep(for: .seconds(3))
                        await send(.hideTabIndicator)
                    }
                    .cancellable(id: HRMirrorCancelID.tabIndicatorTimer)
                )

            // Received from iPhone via WatchConnectivity — starts elapsed-time timer.
            // Preparing overlay stays until first hrReceived (real sensor data).
            case .countdownFinished:
                return .run { [clock] send in
                    for await _ in clock.timer(interval: .milliseconds(100)) {
                        await send(.subSecondTick)
                    }
                }
                .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)

            case .stop:
                state.isPreparing = false
                return .merge(
                    .cancel(id: HRMirrorCancelID.hrQuery),
                    .cancel(id: HRMirrorCancelID.subSecondTimer),
                    .cancel(id: HRMirrorCancelID.countdown),
                    .cancel(id: HRMirrorCancelID.tabIndicatorTimer),
                    .run { [watchWorkoutSessionClient = watchWorkoutSessionClient] _ in
                        await watchWorkoutSessionClient.endSession()
                    }
                )

            case .view(.onAppear):
                return .none
            }
        }
    }

    // MARK: - Private

    /// Derives the `HeartRateZone` for a given BPM relative to the user's max heart rate.
    private func heartRateZone(bpm: Int, max: Int) -> HeartRateZone {
        guard max > 0 else { return .resting }
        let percentage = Double(bpm) / Double(max)
        return HeartRateZone.allCases.first { $0.percentageRange.contains(percentage) } ?? .resting
    }

}

// MARK: - Cancel IDs

/// Cancel identifiers used by `HRMirrorFeature` long-running effects.
///
/// Declared outside the `@Reducer` to avoid `@MainActor` isolation
/// that would prevent conformance to `Sendable` (required by `cancellable(id:)`).
private nonisolated enum HRMirrorCancelID: Hashable, Sendable {

    /// Identifies the `HKLiveWorkoutBuilder` heart rate stream.
    case hrQuery

    /// Identifies the 100 ms sub-second timer for smooth centisecond display.
    case subSecondTimer

    /// Identifies the 3 s auto-hide timer for TabView indicator dots.
    case tabIndicatorTimer

    /// Identifies the 3-2-1 countdown before the workout begins.
    case countdown

}
