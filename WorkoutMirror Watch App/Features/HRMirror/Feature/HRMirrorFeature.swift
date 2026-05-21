//
//  HRMirrorFeature.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 25/03/2026.
//

import ComposableArchitecture
import HealthKit
import OSLog
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
                let zone = state.heartRateZone
                // Watch-primary: send HR via HealthKit's native mirroring channel
                // (sendToRemoteWorkoutSession) instead of WatchConnectivity.
                // iPhone receives it in DefaultTrainingManager.didReceiveDataFromRemoteWorkoutSession.
                return .run { [watchWorkoutSessionClient = watchWorkoutSessionClient, bpm, zone] _ in
                    await watchWorkoutSessionClient.sendHRToRemote(bpm, Date())
                    await WorkoutFileLogger.shared.logHRIfNeeded(bpm: bpm)
                }

            case .subSecondTick:
                guard !state.isPaused else { return .none }
                state.elapsedSeconds += 0.1
                return .none

            // MARK: - iPhone Events

            case .workoutPaused:
                state.isPaused = true
                return .merge(
                    .cancel(id: HRMirrorCancelID.subSecondTimer),
                    .run { _ in await WorkoutFileLogger.shared.log("PAUSED") }
                )

            case .workoutResumed(let elapsed):
                state.elapsedSeconds = elapsed
                state.isPaused = false
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("RESUMED") },
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .milliseconds(100)) {
                            await send(.subSecondTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)
                )

            case .workoutTick(let elapsed):
                // iPhone is source of truth — reset to exact value each second.
                state.elapsedSeconds = elapsed
                return .none

            case .sessionStateChanged(let sessionState):
                // HealthKit propagated a pause/resume from iPhone's mirrored session.
                // Mirror the state so Watch UI (isPaused, subSecondTimer) stays in sync.
                let isPausedSnapshot = state.isPaused
                Logger.hrMirror.info("sessionStateChanged → \(sessionState.rawValue), isPaused was: \(isPausedSnapshot)")
                switch sessionState {
                case .paused:
                    state.isPaused = true
                    return .merge(
                        .cancel(id: HRMirrorCancelID.subSecondTimer),
                        .run { _ in await WorkoutFileLogger.shared.log("PAUSED (HealthKit)") }
                    )
                case .running:
                    guard state.isPaused else {
                        Logger.hrMirror.debug("sessionStateChanged .running — already running, skipping timer restart")
                        return .none
                    }
                    state.isPaused = false
                    return .merge(
                        .run { _ in await WorkoutFileLogger.shared.log("RESUMED (HealthKit)") },
                        .run { [clock] send in
                            for await _ in clock.timer(interval: .milliseconds(100)) {
                                await send(.subSecondTick)
                            }
                        }
                        .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)
                    )
                default:
                    return .none
                }

            // MARK: - View Actions

            case .view(.pauseResumeTapped):
                // Watch-primary: pause/resume the HKWorkoutSession directly.
                // HealthKit mirroring propagates the state change to iPhone automatically —
                // no WatchConnectivity events needed.
                //
                // Timer management must happen HERE, not only in sessionStateChanged.
                // Reason: view action toggles isPaused synchronously; by the time
                // sessionStateChanged(.running) fires, isPaused is already false
                // so its guard would skip the timer restart.
                let isResuming = state.isPaused  // true means we're about to resume
                state.isPaused.toggle()
                if isResuming {
                    return .merge(
                        .run { _ in await WorkoutFileLogger.shared.log("RESUMED (Watch tap)") },
                        .run { [watchWorkoutSessionClient = watchWorkoutSessionClient] _ in
                            await watchWorkoutSessionClient.togglePause()
                        },
                        .run { [clock] send in
                            for await _ in clock.timer(interval: .milliseconds(100)) {
                                await send(.subSecondTick)
                            }
                        }
                        .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)
                    )
                } else {
                    return .merge(
                        .run { _ in await WorkoutFileLogger.shared.log("PAUSED (Watch tap)") },
                        .cancel(id: HRMirrorCancelID.subSecondTimer),
                        .run { [watchWorkoutSessionClient = watchWorkoutSessionClient] _ in
                            await watchWorkoutSessionClient.togglePause()
                        }
                    )
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
                Logger.hrMirror.info("tab selected → \(String(describing: tab))")
                state.selectedTab = tab
                return .none

            case .view(.stopLongPressConfirmed):
                Logger.hrMirror.info("Stop confirmed via long-press on Watch")
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("[UserAction] Stop long-press confirmed on Watch") },
                    .send(.stop)
                )

            // MARK: - Lifecycle

            case .start:
                let activityType = state.activityType
                return .merge(
                    .run { [activityType] _ in
                        await WorkoutFileLogger.shared.reset()
                        await WorkoutFileLogger.shared.log("STARTED — activityType: \(activityType.rawValue)")
                    },
                    .run { [extendedRuntimeClient = extendedRuntimeClient] _ in
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
                    // Listen for pause/resume propagated from iPhone via HealthKit mirroring.
                    .run { [watchWorkoutSessionClient = watchWorkoutSessionClient] send in
                        for await state in watchWorkoutSessionClient.sessionStateStream() {
                            await send(.sessionStateChanged(state))
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.sessionStateStream),
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
                state.isSaving = true
                return .merge(
                    .cancel(id: HRMirrorCancelID.hrQuery),
                    .cancel(id: HRMirrorCancelID.subSecondTimer),
                    .cancel(id: HRMirrorCancelID.countdown),
                    .cancel(id: HRMirrorCancelID.tabIndicatorTimer),
                    .cancel(id: HRMirrorCancelID.sessionStateStream),
                    .run { [watchWorkoutSessionClient = watchWorkoutSessionClient,
                            watchClient = watchClient, clock] send in
                        let savingStart = ContinuousClock.now
                        await WorkoutFileLogger.shared.log("STOPPED — ending HealthKit session")
                        await watchWorkoutSessionClient.endSession()
                        await WorkoutFileLogger.shared.log("NOTIFY — sending .workoutSaved to iPhone")
                        await watchClient.sendWorkoutEvent(.workoutSaved)
                        await WorkoutFileLogger.shared.log("DONE — transferring log to iPhone")
                        await watchClient.transferLogFile()
                        // Ensure "Saving…" overlay is visible for at least 1.5s
                        let elapsed = ContinuousClock.now - savingStart
                        if elapsed < .seconds(1.5) {
                            try? await clock.sleep(for: .seconds(1.5) - elapsed)
                        }
                        await send(.delegate(.didFinishSaving))
                    }
                )

            case .delegate:
                return .none

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

    /// Identifies the stream that delivers pause/resume state from the Watch session delegate.
    case sessionStateStream

}
