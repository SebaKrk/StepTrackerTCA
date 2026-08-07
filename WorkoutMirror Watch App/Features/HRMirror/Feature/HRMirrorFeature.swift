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
/// 2. `HKLiveWorkoutBuilder` yields live BPM readings, forwarded to iPhone via HealthKit
///    mirroring channel (`sendToRemoteWorkoutSession`) — NOT WatchConnectivity (R2).
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
                state.heartRate = Int(bpm)
                state.heartRateZone = HeartRateZone.zone(bpm: Int(bpm), maxHR: state.maxHeartRate)
                // Credit effort points for the stretch since the previous sample.
                // The date always advances (even for bpm=0 artifacts) so a sensor
                // dropout is never retroactively credited to the next valid zone.
                let sampleDate = Date()
                if let previousSampleDate = state.lastEffortSampleDate {
                    state.effortPoints.add(
                        bpm: Int(bpm),
                        duration: sampleDate.timeIntervalSince(previousSampleDate),
                        maxHR: state.maxHeartRate
                    )
                }
                state.lastEffortSampleDate = sampleDate
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
                let locationType = state.locationType
                // Show countdown overlay immediately so user never sees the workout view
                // with stopwatch=00:00 before iPhone's countdownStart event arrives.
                state.isCountingDown = true
                state.countdownRemaining = 3
                return .merge(
                    .run { [activityType] _ in
                        await WorkoutFileLogger.shared.reset()
                        await WorkoutFileLogger.shared.log("STARTED — activityType: \(activityType.rawValue)")
                    },
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.countdownTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.countdown, cancelInFlight: true),
                    .run { [extendedRuntimeClient = extendedRuntimeClient] _ in
                        await extendedRuntimeClient.start()
                    },
                    // Start HealthKit session immediately — HR readings accumulate
                    // while iPhone finishes its countdown.
                    .run { [watchWorkoutSessionClient = watchWorkoutSessionClient, activityType, locationType] send in
                        for await bpm in await watchWorkoutSessionClient.startSession(activityType, locationType) {
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
                    // Defensive timer start — don't rely on `.countdownFinished` from iPhone.
                    // If WC delivery drops that event (AsyncStream race / queue latency on
                    // unreachable iPhone), timer would never start, leaving UI frozen at
                    // 00:00 even though HK session is running. `.countdownFinished` will
                    // restart this same cancellable ID — no duplicate timer.
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .milliseconds(100)) {
                            await send(.subSecondTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true),
                    .run { send in
                        try? await Task.sleep(for: .seconds(3))
                        await send(.hideTabIndicator)
                    }
                    .cancellable(id: HRMirrorCancelID.tabIndicatorTimer)
                )

            // Received from iPhone via WatchConnectivity — restarts elapsed-time timer
            // (defensive: timer already started in `.start`, but cancelInFlight ensures
            // a single fresh ticker after countdown signal). Preparing overlay stays
            // until first hrReceived (real sensor data).
            case .countdownStart:
                // Watch already starts its countdown in `.start` handler (sec 0, before WC
                // event arrives). If already counting, ignore — resetting here would visibly
                // jump back from 2 to 3, looking like "the countdown restarted itself".
                guard !state.isCountingDown else {
                    return .run { _ in await WorkoutFileLogger.shared.log("[Lifecycle] countdownStart received — already counting, ignored") }
                }
                state.isCountingDown = true
                state.countdownRemaining = 3
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("[Lifecycle] countdownStart received") },
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.countdownTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.countdown, cancelInFlight: true)
                )

            case .countdownTick:
                state.countdownRemaining -= 1
                guard state.countdownRemaining <= 0 else { return .none }
                state.isCountingDown = false
                return .cancel(id: HRMirrorCancelID.countdown)

            case .countdownFinished:
                // Defensive: clear overlay even if local ticker hasn't reached zero yet.
                state.isCountingDown = false
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("[Lifecycle] countdownFinished received") },
                    .cancel(id: HRMirrorCancelID.countdown),
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .milliseconds(100)) {
                            await send(.subSecondTick)
                        }
                    }
                    .cancellable(id: HRMirrorCancelID.subSecondTimer, cancelInFlight: true)
                )

            case .stop:
                // Idempotency guard: `.workoutEnded` can arrive DUPLICATED (the wrapper's
                // timeout-retry re-sends even though the first delivery may have arrived) or
                // race with the long-press. A second pass re-enabled "Saving…",
                // consumed the already-consumed values (nil) and REPLACED the real summary
                // with the "unavailable" fallback.
                guard !state.isSaving, state.summaryPhase == .hidden else {
                    return .run { _ in
                        await WorkoutFileLogger.shared.log("[End] duplicate .stop ignored (already saving/summarized)")
                    }
                }
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

                        // UUID and summary are consumed TOGETHER, after a shared retry window —
                        // the save may be done by an asynchronous safety-net (`.ended`), and the UUID
                        // drives the whole plan-link/badge on the iPhone. Previously the retry covered
                        // only the summary: the Watch showed "saved" while `.workoutSaved`
                        // silently never went out.
                        var uuid = await watchWorkoutSessionClient.consumeLastSavedWorkoutUUID()
                        var summary = await watchWorkoutSessionClient.consumeLastSavedWorkoutSummary()
                        if uuid == nil || summary == nil {
                            try? await clock.sleep(for: .seconds(1))
                            if uuid == nil {
                                uuid = await watchWorkoutSessionClient.consumeLastSavedWorkoutUUID()
                            }
                            if summary == nil {
                                summary = await watchWorkoutSessionClient.consumeLastSavedWorkoutSummary()
                            }
                        }

                        if let uuid {
                            await WorkoutFileLogger.shared.log("NOTIFY — sending .workoutSaved(uuid=\(uuid.uuidString)) to iPhone")
                            await watchClient.sendWorkoutEvent(.workoutSaved(workoutUUID: uuid))
                        } else {
                            await WorkoutFileLogger.shared.log("NOTIFY — .workoutSaved skipped (no UUID after retry, save likely failed)")
                        }
                        await WorkoutFileLogger.shared.log("DONE — transferring log to iPhone")
                        await watchClient.transferLogFile()
                        // Ensure "Saving…" overlay is visible for at least 1.5s
                        let elapsed = ContinuousClock.now - savingStart
                        if elapsed < .seconds(1.5) {
                            try? await clock.sleep(for: .seconds(1.5) - elapsed)
                        }
                        // Watch is the primary session owner — it shows the immediate
                        // summary from finishWorkout(); dismissal happens on Done tap.
                        await send(.savedSummaryLoaded(summary))
                    }
                )

            case .savedSummaryLoaded(let summary):
                state.isSaving = false
                state.summaryPhase = .presented(summary)
                return .run { _ in
                    await WorkoutFileLogger.shared.log("SUMMARY (Watch) — shown (hasData=\(summary != nil))")
                }

            case .view(.summaryDoneTapped):
                return .send(.delegate(.didFinishSaving))

            case .delegate:
                return .none

            case .view(.onAppear):
                return .none
            }
        }
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
