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
/// The Watch acts as a **passive HR sensor** — it never starts its own `HKWorkoutSession`.
/// Instead it:
///
/// 1. Reads live heart rate samples from the Watch sensor via `HRQueryClient`
///    (backed by `HKAnchoredObjectQuery`).
/// 2. Calculates the current `HeartRateZone` and forwards each reading back to the
///    paired iPhone as a `WatchWorkoutEvent.hrReading` message.
/// 3. Maintains an elapsed-time counter that mirrors the workout clock on iPhone,
///    accounting for pause / resume events sent from the phone.
@Reducer
struct HRMirrorFeature {

    // MARK: - Dependencies

    @Dependency(\.hrQueryClient) var hrQueryClient
    @Dependency(\.watchConnectivityClientAW) var watchClient
    @Dependency(\.extendedRuntimeClient) var extendedRuntimeClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Internal Actions

            case .hrReceived(let bpm):
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
                return .run { send in
                    while !Task.isCancelled {
                        try await Task.sleep(for: .milliseconds(100))
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

            // MARK: - Internal Start

            case .start:
                return .merge(
                    .run { [extendedRuntimeClient = extendedRuntimeClient] send in
                        await extendedRuntimeClient.start()
                    },
                    .run { [hrQueryClient = hrQueryClient] send in
                        for await bpm in hrQueryClient.startQuery() {
                            await send(.hrReceived(bpm))
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.hrQuery),
                    .run { send in
                        while !Task.isCancelled {
                            try await Task.sleep(for: .milliseconds(100))
                            await send(.subSecondTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.subSecondTimer),
                    .run { send in
                        try? await Task.sleep(for: .seconds(3))
                        await send(.hideTabIndicator)
                    }
                    .cancellable(id: HRMirrorCancelID.tabIndicatorTimer)
                )

            case .view(.onAppear):
                return .none
            }
        }
    }

    // MARK: - Private

    /// Derives the `HeartRateZone` for a given BPM relative to the user's max heart rate.
    ///
    /// Iterates `HeartRateZone.allCases` in order and returns the first zone
    /// whose `percentageRange` contains the current HR percentage.
    /// Falls back to `.resting` if no zone matches (e.g. BPM above max).
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

    /// Identifies the `HKAnchoredObjectQuery` heart rate stream.
    case hrQuery

    /// Identifies the 100 ms sub-second timer for smooth centisecond display.
    case subSecondTimer

    /// Identifies the 3 s auto-hide timer for TabView indicator dots.
    case tabIndicatorTimer

}
