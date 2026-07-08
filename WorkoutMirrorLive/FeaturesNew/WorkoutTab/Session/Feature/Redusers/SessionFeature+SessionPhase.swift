//
//  SessionFeature+SessionPhase.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import HealthHub
import HealthKit
import OSLog
import SharedModels
import SharedModels

extension SessionFeature {

    var sessionPhaseReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case let .sessionViewStateChange(value):
                // Re-entry guard (review cluster D): an End tap can race with the mirrored
                // `.ended` (a "timed out" send is sometimes delivered) — a second `.finishedOnWatch`
                // would do a second teardown + `dismiss()` on a closed store (TCA warning).
                if value == .finishedOnWatch, state.sessionState == .finishedOnWatch {
                    return .none
                }
                state.sessionState = value

                if value == .waitingForWatch {
                    // Configure CountDownView for waiting mode: same gray ring, no timer, only
                    // text below. Phase flips to `.countingDown` after Watch starts mirroring,
                    // and the ring stays continuous — only the overlay content (trim + number) appears.
                    state.countDown.phase = .waitingForWatch
                    return .none
                }

                if value == .countdown && state.countDown.phase == .waitingForWatch {
                    // Watch-primary transition: Watch acknowledged mirroring start.
                    // Flip CountDownView from waiting → counting, kick off the local 3-2-1
                    // timer, AND tell Watch to start its synced 3-2-1 overlay.
                    state.countDown.phase = .countingDown
                    return .merge(
                        .send(.countDown(.startCountDown)),
                        .run { [sessionClient] _ in
                            // HK mirroring channel — reliable even when WC `reachable=false`
                            // (per CLAUDE.md R2). This branch is reached only when phase was
                            // `.waitingForWatch`, which only happens in Watch-primary mode,
                            // so the mirrored session always exists.
                            _ = await sessionClient.sendLifecycleEventToWatch(.countdownStart)
                        }
                    )
                }

                if value == .session {
                    // Safety net: set .running immediately so controls show pause.
                    // On real device, workoutSessionStateStream() will confirm with
                    // the actual HealthKit state. On simulator, HK never emits .running.
                    state.controls.sessionState = .running

                    let mode = state.workoutMode
                    let initialState = WorkoutSessionActivityAttributes.ContentState(
                        heartRate: 0,
                        heartRateZone: .resting,
                        heartRatePercentage: 0,
                        activeEnergy: 0,
                        maxHeartRate: 0,
                        averageHeartRate: 0
                    )
                    let phases = state.trainingSession?.phases ?? []

                    // Reset elapsed-time counter at session start.
                    // Must happen before the tick timer starts to avoid stale values
                    // from a previous workout in the same app session.
                    sessionClient.resetElapsed()

                    let workoutTitle = state.selectedWorkout.title
                    Task {
                        await WorkoutFileLogger.shared.reset()
                        await WorkoutFileLogger.shared.log("STARTED — mode: \(mode), workout: \(workoutTitle)")
                    }

                    switch mode {

                    case .watchPrimary:
                        // Watch owns the HKWorkoutSession. Pause/resume sync automatically
                        // through HealthKit mirroring — no WatchConnectivity events needed
                        // for session state. HR comes via sendToRemoteWorkoutSession.
                        return .merge(
                            // App Intent observers (Pause/Resume/End from Live Activity).
                            // Long-running effects active while session is alive; cancelled on
                            // transition to .summary alongside other session-scoped streams.
                            .run { send in
                                for await _ in NotificationCenter.default.notifications(named: .workoutPauseRequested) {
                                    await send(.intentPauseRequested)
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.intentPauseObserver),
                            .run { send in
                                for await _ in NotificationCenter.default.notifications(named: .workoutResumeRequested) {
                                    await send(.intentResumeRequested)
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.intentResumeObserver),
                            .run { send in
                                for await _ in NotificationCenter.default.notifications(named: .workoutEndRequested) {
                                    await send(.intentEndRequested)
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.intentEndObserver),
                            .run { [sessionClient] send in
                                for await sessionState in await sessionClient.workoutSessionStateStream() {
                                    await send(.controls(.sessionStateUpdated(sessionState)))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.sessionStateStream),
                            // Mirroring-link status (IOS-00098-G) — drives the connection-lost
                            // banner, tick suspension and End-button gating.
                            .run { [sessionClient] send in
                                for await status in await sessionClient.watchConnectionStatusStream() {
                                    await send(.watchConnectionStatusChanged(status))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.watchConnectionStream),
                            .run { [sessionClient] send in
                                for await metrics in await sessionClient.workoutMetricsStream() {
                                    await send(.live(.workoutMetrics(metrics)))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.metricsStream),
                            .send(.live(.liveActivity(.workout(.start(workoutName: state.selectedWorkout.title, initialState: initialState))))),
                            .send(.live(.setupPhasePanel(phases))),
                            .run { [sessionClient,
                                    maxHR = state.live.maxHeartRate,
                                    activityTypeRaw = state.selectedWorkout.hkType.rawValue] _ in
                                Logger.session.info("Watch-primary — sending workoutStarted + countdownFinished via HK channel")
                                // HK mirroring channel — reliable even when WC `reachable=false`
                                // (per CLAUDE.md R2). Carries `maxHeartRate` which the Watch needs
                                // for zone calculations; dropping this event (as the WC path does
                                // on unreachable) leaves the Watch with `maxHR = 0` → dial stays at 0%.
                                _ = await sessionClient.sendLifecycleEventToWatch(
                                    .workoutStarted(activityType: activityTypeRaw, elapsedSeconds: 0, maxHeartRate: maxHR)
                                )
                                _ = await sessionClient.sendLifecycleEventToWatch(.countdownFinished)
                            },
                            .run { [watchClient = watchConnectivityClient] send in
                                for await event in watchClient.incomingEventStream() {
                                    await send(.watchEventReceived(event))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.watchEventStream),
                            .run { [clock] send in
                                for await _ in clock.timer(interval: .seconds(1)) {
                                    await send(.watchTickEffect)
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.watchTickTimer)
                        )

                    case .iPhoneStandalone:
                        // iPhone owns the HKWorkoutSession. Watch is an optional HR sensor
                        // sending readings via WatchConnectivity.
                        return .merge(
                            .run { [sessionClient] send in
                                for await sessionState in await sessionClient.workoutSessionStateStream() {
                                    await send(.controls(.sessionStateUpdated(sessionState)))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.sessionStateStream),
                            .run { [sessionClient] send in
                                for await metrics in await sessionClient.workoutMetricsStream() {
                                    await send(.live(.workoutMetrics(metrics)))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.metricsStream),
                            .send(.live(.liveActivity(.workout(.start(workoutName: state.selectedWorkout.title, initialState: initialState))))),
                            .send(.live(.setupPhasePanel(phases))),
                            .run { [watchClient = watchConnectivityClient,
                                    maxHR = state.live.maxHeartRate,
                                    activityTypeRaw = state.selectedWorkout.hkType.rawValue] _ in
                                Logger.session.info("iPhone-standalone — sending workoutStarted to Watch")
                                await watchClient.sendWorkoutEvent(
                                    .workoutStarted(activityType: activityTypeRaw, elapsedSeconds: 0, maxHeartRate: maxHR)
                                )
                                await watchClient.sendWorkoutEvent(.countdownFinished)
                            },
                            .run { [watchClient = watchConnectivityClient] send in
                                for await event in watchClient.incomingEventStream() {
                                    await send(.watchEventReceived(event))
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.watchEventStream),
                            .run { [clock] send in
                                for await _ in clock.timer(interval: .seconds(1)) {
                                    await send(.watchTickEffect)
                                }
                            }
                            .cancellable(id: SessionWatchCancelID.watchTickTimer)
                        )
                    }

                } else if value == .summary {
                    state.summary.failureDebugInfo = "mode: \(state.workoutMode)"

                    // Freeze the live effort points before the session tears down —
                    // AppTabNewFeature links it to the HKWorkout on `.workoutSaved`.
                    captureEffortScoreSnapshot(state)

                    // Convert hrBuffer and phaseTimestamps to simple tuples for SummaryFeature
                    let hrData = state.live.hrBuffer.map { (date: $0.date, bpm: $0.bpm) }
                    let phases = state.live.phasePanel?.phaseTimestamps.map {
                        (name: $0.phaseName, start: $0.startDate, end: $0.endDate)
                    } ?? []

                    // Auto-disconnect the Gym Room broadcast when the workout ends.
                    // `leaveTapped` stops browsing + cancels effects inside the feature;
                    // then we clear the state so `joined` does not persist between workouts.
                    let gymRoomCleanup: Effect<Action> = state.joinLiveClass != nil
                        ? .send(.joinLiveClass(.view(.leaveTapped)))
                        : .none

                    return .merge(
                        .cancel(id: SessionWatchCancelID.sessionStateStream),
                        .cancel(id: SessionWatchCancelID.watchTickTimer),
                        .cancel(id: SessionWatchCancelID.metricsStream),
                        .cancel(id: SessionWatchCancelID.intentPauseObserver),
                        .cancel(id: SessionWatchCancelID.intentResumeObserver),
                        .cancel(id: SessionWatchCancelID.intentEndObserver),
                        .cancel(id: SessionWatchCancelID.watchConnectionStream),
                        // Symmetry with .finishedOnWatch (review, minor): End no longer cancels
                        // streams before the send — the teardown must cover everything.
                        .cancel(id: SessionWatchCancelID.watchEventStream),
                        .send(.live(.liveActivity(.workout(.stop)))),
                        .send(.live(.liveActivity(.timer(.stop)))),
                        .send(.summary(.setHRData(hrBuffer: hrData, phaseTimestamps: phases))),
                        .send(.summary(.setEffortPoints(
                            points: state.live.effortPoints.points,
                            dominantZone: state.live.effortPoints.secondsByZone.max { $0.value < $1.value }?.key
                        ))),
                        gymRoomCleanup
                    )
                } else if value == .finishedOnWatch {
                    // Watch-primary post-end (IOS-00098-E): same session teardown as `.summary`,
                    // but no summary data wiring — the Watch (primary owner) shows the immediate
                    // summary and the app-level listener (AppTabNewFeature) consumes `.workoutSaved`
                    // for the plan link, so `watchEventStream` can be cancelled too.
                    //
                    // No interstitial screen on iPhone (decyzja usera 2026-07-03): after teardown
                    // the session simply dismisses — the confirmation lives on the wrist, and
                    // "wyniki w Historii" is carried durably by the pending-results badge (F).

                    // Freeze the live effort points before teardown (same as `.summary`).
                    captureEffortScoreSnapshot(state)

                    let gymRoomCleanup: Effect<Action> = state.joinLiveClass != nil
                        ? .send(.joinLiveClass(.view(.leaveTapped)))
                        : .none

                    return .merge(
                        .cancel(id: SessionWatchCancelID.sessionStateStream),
                        .cancel(id: SessionWatchCancelID.watchTickTimer),
                        .cancel(id: SessionWatchCancelID.metricsStream),
                        .cancel(id: SessionWatchCancelID.intentPauseObserver),
                        .cancel(id: SessionWatchCancelID.intentResumeObserver),
                        .cancel(id: SessionWatchCancelID.intentEndObserver),
                        .cancel(id: SessionWatchCancelID.watchEventStream),
                        .cancel(id: SessionWatchCancelID.watchConnectionStream),
                        .send(.live(.liveActivity(.workout(.stop)))),
                        .send(.live(.liveActivity(.timer(.stop)))),
                        gymRoomCleanup,
                        .run { _ in await self.dismiss() }
                    )
                }
                return .none

            default:
                return .none
            }
        }
    }

    // MARK: - Effort points snapshot

    /// Freezes the live effort points accumulator into `@Shared(.pendingEffortScore)`
    /// at workout end, so `AppTabNewFeature` can link it to the `HKWorkout` when
    /// `.workoutSaved` arrives (IOS-00099-F5). The value is the same one shown on
    /// screen and sent to GymRoom — a result is a result, never recomputed.
    ///
    /// Skips sessions that earned nothing (no HR / 0 points): no record is written,
    /// so the History section stays hidden for them.
    private func captureEffortScoreSnapshot(_ state: State) {
        @Shared(.pendingEffortScore) var pendingEffortScore
        let accumulator = state.live.effortPoints
        guard accumulator.points > 0 else { return }
        // An un-consumed prior snapshot here means the previous workout's
        // `.workoutSaved` never arrived (save failure) — log before overwriting so
        // a lost link is traceable rather than silent.
        if let stale = pendingEffortScore {
            Logger.session.notice("pendingEffortScore overwritten before consume (\(stale.points) pts dropped)")
        }
        $pendingEffortScore.withLock {
            $0 = PendingEffortScore(
                points: accumulator.points,
                secondsByZone: accumulator.secondsByZone,
                workoutStartDate: state.live.hrBuffer.first?.date ?? now,
                weightsVersion: EffortPointsScoring.currentWeightsVersion
            )
        }
    }
}
