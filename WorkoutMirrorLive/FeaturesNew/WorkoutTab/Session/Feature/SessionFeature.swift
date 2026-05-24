//
//  SessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import OSLog
import SharedModels
import HealthKit

@Reducer
struct SessionFeature {

    // MARK: - Dependency

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.continuousClock) var clock

    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

                // MARK: - setWorkoutMode

            case let .setWorkoutMode(mode):
                state.workoutMode = mode
                return .run { [sessionClient] _ in
                    await sessionClient.setWorkoutMode(mode)
                }

                // MARK: - sessionViewStateChange

            case let .sessionViewStateChange(value):
                state.sessionState = value

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
                                Logger.session.info("Watch-primary — sending workoutStarted + countdownFinished")
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

                    // Convert hrBuffer and phaseTimestamps to simple tuples for SummaryFeature
                    let hrData = state.live.hrBuffer.map { (date: $0.date, bpm: $0.bpm) }
                    let phases = state.live.phasePanel?.phaseTimestamps.map {
                        (name: $0.phaseName, start: $0.startDate, end: $0.endDate)
                    } ?? []

                    // IPAD-0087: auto-disconnect Gym Room broadcastu gdy workout kończy się.
                    // `leaveTapped` zatrzymuje browsing + cancel'uje effecty wewnątrz feature'a;
                    // potem kasujemy state, żeby `joined` nie pozostał między treningami.
                    let gymRoomCleanup: Effect<Action> = state.joinLiveClass != nil
                        ? .send(.joinLiveClass(.view(.leaveTapped)))
                        : .none

                    var effects: [Effect<Action>] = [
                        .cancel(id: SessionWatchCancelID.sessionStateStream),
                        .cancel(id: SessionWatchCancelID.watchTickTimer),
                        .cancel(id: SessionWatchCancelID.metricsStream),
                        .cancel(id: SessionWatchCancelID.hrReadingTimeout),
                        .send(.live(.liveActivity(.workout(.stop)))),
                        .send(.live(.liveActivity(.timer(.stop)))),
                        .send(.summary(.setHRData(hrBuffer: hrData, phaseTimestamps: phases))),
                        gymRoomCleanup
                    ]
                    // iPhone-standalone: iPhone saved the workout — skip .saving, go straight to polling.
                    // Watch-primary: keep watchEventStream alive for .workoutSaved from Watch.
                    if state.workoutMode == .iPhoneStandalone {
                        effects.append(.send(.summary(.workoutSavedReceived)))
                    }
                    return .merge(effects)
                }
                return .none

            case .makeCalculationForSession:
                return .run { send in
                    // Fallback values when HK permission for age/sex is missing — without
                    // these the zone calculation defaults to .resting (every HR is "below 50%
                    // of 0 = resting") and the UI shows 0% / "SPOCZYNEK" forever. Defaults
                    // are conservative (age=30, sex=.notSet) and produce ~190 bpm max HR.
                    let age = (try? await personalDataClient.getAge()) ?? 30
                    let sex = (try? await personalDataClient.getBiologicalSex()) ?? .notSet
                    let maxHR = Int(maxHeartRateClient.fromAge(age, sex))
                    await WorkoutFileLogger.shared.log("[MaxHR] computed: \(maxHR) (age=\(age), sex=\(String(describing: sex)))")
                    await send(.setMaxHR(maxHR))
                }

            case let .setMaxHR(value):
                let isSessionActive = state.sessionState == .session
                return .merge(
                    .send(.live(.setupMaxHeartRate(value))),
                    isSessionActive ? .run { [watchClient = watchConnectivityClient] _ in
                        await watchClient.sendWorkoutEvent(.maxHRUpdated(value))
                    } : .none
                )

                // MARK: - View Action

            case .view(.viewDidAppear):
                return .run { [workout = state.selectedWorkout,
                               trainingSession = state.trainingSession,
                               watchClient = watchConnectivityClient,
                               sessionClient] send in
                    await watchClient.initializeWatchConnectivity()
                    let watchStatus = await watchClient.checkWatchStatus()
                    Logger.session.info("viewDidAppear — watchStatus: \(watchStatus.rawValue), workout: \(workout.title)")

                    if watchStatus == .ready {
                        // Watch-primary: iPhone does NOT start its own HKWorkoutSession.
                        // Watch starts the primary session and mirrors it to iPhone.
                        await send(.setWorkoutMode(.watchPrimary))
                        Logger.session.info("Watch-primary mode — launching Watch workout")
                        do {
                            try await sessionClient.startWatchWorkout(workout.hkType)
                            Logger.session.info("startWatchWorkout succeeded")
                        } catch {
                            // Watch launch failed — fall back to iPhone-standalone.
                            Logger.session.error("startWatchWorkout FAILED: \(error) — falling back to iPhone-standalone")
                            await send(.setWorkoutMode(.iPhoneStandalone))
                            try await sessionClient.selectedWorkout(workout.hkType)
                        }
                    } else {
                        // iPhone-standalone: iPhone owns the HKWorkoutSession.
                        await send(.setWorkoutMode(.iPhoneStandalone))
                        Logger.session.info("iPhone-standalone mode — Watch unavailable (\(watchStatus.rawValue))")
                        try await sessionClient.selectedWorkout(workout.hkType)
                        Logger.session.info("selectedWorkout set → DefaultWorkoutManager.prepareWorkout() triggered")
                    }

                    await send(.controls(.setWorkoutType(workout)))
                    await send(.makeCalculationForSession)
                    await send(.summary(.setTrainingSession(trainingSession)))
                }

            case .view(.heartRateZoneButtonTapped):
                state.destination = .openHeartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none

            case .view(.timerButtonTapped):
                return .send(.live(.userStopwatch(.view(.toggleVisibility))))

            case .view(.joinLiveClassToolbarButtonTapped):
                // Tap ikony obok HR zones: utwórz state przy pierwszym tap'ie, pokaż sheet.
                // Kolejne tapy: state istnieje (broadcast trwa) — tylko pokaż sheet.
                if state.joinLiveClass == nil {
                    state.joinLiveClass = JoinLiveClassFeature.State()
                }
                state.isJoinLiveClassSheetPresented = true
                return .none

                // MARK: - Gym Room (IPAD-0087)

            case .joinLiveClassSheetDismissed:
                // Swipe-down / X — broadcast TRWA, state żyje.
                state.isJoinLiveClassSheetPresented = false
                return .none

            case .joinLiveClass(.delegate(.didDismiss)):
                // Sheet schowany (Join tapped / X / swipe-down) — broadcast TRWA,
                // state żyje, ikona toolbar dalej pokazuje connected.
                state.isJoinLiveClassSheetPresented = false
                return .none

            case .joinLiveClass(.delegate(.didLeave)):
                // User explicit zakończył klasę — kasuj state + ukryj sheet.
                state.joinLiveClass = nil
                state.isJoinLiveClassSheetPresented = false
                return .none

            case .joinLiveClass:
                return .none

                // MARK: - Destination

            case .destination(_):
                return .none

                // MARK: - Child

            case .countDown(.closeView):
                return .send(.sessionViewStateChange(.session))

            case .watchTickEffect:
                // Increment internal counter (Watch-primary: iPhone has no HealthKit builder).
                // The updated value is also returned by `elapsedTimeAt` so ControlsView
                // reads the correct elapsed time on the next TimelineView frame.
                return .run { [sessionClient, watchClient = watchConnectivityClient] _ in
                    let elapsed = sessionClient.incrementElapsed()
                    await watchClient.sendWorkoutEvent(.workoutTick(elapsedSeconds: elapsed))
                }

            case .controls(.sessionStateUpdated(.paused)):
                let mode = state.workoutMode
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("PAUSED") },
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    mode == .iPhoneStandalone ? .run { [watchClient = watchConnectivityClient] _ in
                        // iPhone-standalone: notify Watch via WatchConnectivity.
                        // Watch-primary: HealthKit mirroring propagates pause automatically.
                        await watchClient.sendWorkoutEvent(.workoutPaused)
                    } : .none
                )

            case .controls(.sessionStateUpdated(.running)):
                guard state.controls.sessionState == .paused else { return .none }
                let mode = state.workoutMode
                let elapsed = state.controls.elapsedTime
                return .merge(
                    .run { _ in await WorkoutFileLogger.shared.log("RESUMED") },
                    mode == .iPhoneStandalone ? .run { [elapsed, watchClient = watchConnectivityClient] _ in
                        await watchClient.sendWorkoutEvent(.workoutResumed(elapsedSeconds: elapsed))
                    } : .none,
                    .run { [sessionClient] _ in
                        // Reset interpolation baseline so elapsedAt(date) doesn't include pause duration.
                        sessionClient.markResumeElapsed()
                    },
                    .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.watchTickEffect)
                        }
                    }
                    .cancellable(id: SessionWatchCancelID.watchTickTimer, cancelInFlight: true)
                )

            case .controls(.sessionStateUpdated(.ended)):
                // Watch-primary: Watch ended the session (e.g. user long-pressed Stop on Watch).
                // HealthKit mirroring propagated .ended state to iPhone's mirrored session, which
                // arrived here via workoutSessionStateStream() → .controls(.sessionStateUpdated(.ended)).
                //
                // Skip vs. iPhone-initiated end (`case .controls(.view(.endWorkoutButtonTapped))`):
                //   - sendWorkoutEvent(.workoutEnded): Watch initiated this end — no echo back needed.
                //     Watch's HRMirror is already dismissed via .delegate(.didFinishSaving).
                //   - sessionClient.endWorkout(): Watch already called session.end() — calling again
                //     on iPhone's mirrored session is redundant.
                //
                // Only transition iPhone UI to summary. Watch's .workoutSaved event will arrive
                // shortly via WatchConnectivity, triggering HKWorkout fetch in SummaryFeature.
                guard state.workoutMode == .watchPrimary else { return .none }
                guard state.sessionState == .session else { return .none }
                return .merge(
                    .cancel(id: SessionWatchCancelID.watchEventStream),
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    // Watch acknowledged the end (via mirrored .ended state) — no point
                    // continuing to retry the .workoutEnded event.
                    .cancel(id: SessionWatchCancelID.workoutEndedRetry),
                    .run { send in
                        await WorkoutFileLogger.shared.log("WATCH-INITIATED END — mirrored session reached .ended state")
                        await WorkoutFileLogger.shared.log("SUMMARY — entering .saving state, waiting for .workoutSaved from Watch")
                        await send(.sessionViewStateChange(.summary))
                    }
                )

            case .controls(.view(.endWorkoutButtonTapped)):
                return .merge(
                    .cancel(id: SessionWatchCancelID.watchEventStream),
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    .run { [watchClient = watchConnectivityClient, sessionClient] send in
                        await WorkoutFileLogger.shared.log("STOPPED — ending workout")
                        await watchClient.sendWorkoutEvent(.workoutEnded)
                        await WorkoutFileLogger.shared.log("END WORKOUT — calling sessionClient.endWorkout()")
                        await sessionClient.endWorkout()
                        await WorkoutFileLogger.shared.log("END WORKOUT — endWorkout() returned (workout NOT yet saved)")
                        await WorkoutFileLogger.shared.log("SUMMARY — entering .saving state, waiting for .workoutSaved from Watch")
                        await send(.sessionViewStateChange(.summary))
                    },
                    // Retry .workoutEnded if Watch doesn't acknowledge within 15s windows.
                    // WC delivery can take seconds-to-minutes when Watch app is in background
                    // (transferUserInfo queue latency). Each retry is a fresh send attempt —
                    // if any of them lands while Watch is reachable, Watch will end and emit
                    // .workoutSaved, cancelling this effect via the handlers below.
                    .run { [watchClient = watchConnectivityClient] _ in
                        for retry in 1...5 {
                            try? await Task.sleep(for: .seconds(15))
                            await WorkoutFileLogger.shared.log("[Retry] re-sending .workoutEnded (attempt #\(retry))")
                            await watchClient.sendWorkoutEvent(.workoutEnded)
                        }
                    }
                    .cancellable(id: SessionWatchCancelID.workoutEndedRetry, cancelInFlight: true)
                )

                // MARK: - Watch Events

            case .watchEventReceived(.hrReading(let bpm, let timestamp)):
                // HR readings from Watch via WatchConnectivity are only used in
                // iPhone-standalone mode. In Watch-primary mode, HR flows through
                // HealthKit mirroring (sendToRemoteWorkoutSession) and arrives via
                // the metrics stream — not as a WatchConnectivity event.
                guard state.workoutMode == .iPhoneStandalone else { return .none }
                let current = state.live.workoutMetrics
                return .merge(
                    .send(.live(.workoutMetrics(
                        WorkoutMetrics(
                            averageHeartRate: current.averageHeartRate,
                            heartRate: bpm,
                            activeEnergy: current.activeEnergy
                        )
                    ))),
                    .run { [bpm, timestamp, sessionClient] _ in
                        await sessionClient.addHeartRateSample(bpm, timestamp)
                    },
                    .run { [clock] send in
                        try? await clock.sleep(for: .seconds(20))
                        await send(.hrReadingTimedOut)
                    }
                    .cancellable(id: SessionWatchCancelID.hrReadingTimeout, cancelInFlight: true)
                )

            case .watchEventReceived(.workoutPaused):
                // In Watch-primary mode, pause is propagated by HealthKit mirroring —
                // we receive it via sessionStateStream, not WatchConnectivity.
                guard state.workoutMode == .iPhoneStandalone else { return .none }
                guard state.controls.sessionState == .running else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .watchEventReceived(.workoutResumed):
                guard state.workoutMode == .iPhoneStandalone else { return .none }
                guard state.controls.sessionState == .paused else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .hrReadingTimedOut:
                guard state.workoutMode == .iPhoneStandalone else { return .none }
                Logger.session.notice("hrReadingTimeout — no HR from Watch for 20s, resetting to 0")
                return .merge(
                    .run { [sessionClient] _ in sessionClient.resetWatchHeartRate() },
                    .send(.live(.resetHeartRate))
                )

            case .watchEventReceived(.workoutSaved):
                guard state.sessionState == .summary else { return .none }
                return .send(.summary(.workoutSavedReceived))

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
        .ifLet(\.joinLiveClass, action: \.joinLiveClass) {
            JoinLiveClassFeature()
        }
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

    /// Identifies the HKWorkoutSessionState stream (mirrored or iPhone-primary).
    case sessionStateStream

    /// Identifies the stream listening for incoming Watch workout events.
    case watchEventStream

    /// Identifies the one-second clock effect that sends `workoutTick` to Watch.
    case watchTickTimer

    /// Identifies the workout metrics stream (HR + calories).
    case metricsStream

    /// Identifies the 20-second watchdog timer that resets heartRate to 0
    /// when no HR reading has been received from Watch in that window.
    /// Only active in iPhone-standalone mode.
    case hrReadingTimeout

    /// Identifies the retry effect that periodically re-sends `.workoutEnded`
    /// to Watch when iPhone-initiated end may have been queued/dropped via WC.
    /// Cancelled when Watch acknowledges via mirrored `.ended` state or
    /// `.workoutSaved` event.
    case workoutEndedRetry

}
