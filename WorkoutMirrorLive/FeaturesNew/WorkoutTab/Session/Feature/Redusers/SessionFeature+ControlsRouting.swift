//
//  SessionFeature+ControlsRouting.swift
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

extension SessionFeature {

    var controlsRoutingReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .countDown(.closeView):
                return .send(.sessionViewStateChange(.session))

            case .watchTickEffect:
                // Increment internal counter (Watch-primary: iPhone has no HealthKit builder).
                // The updated value is also returned by `elapsedTimeAt` so ControlsView
                // reads the correct elapsed time on the next TimelineView frame.
                let mode = state.workoutMode
                let isLinkLost = state.isWatchConnectionLost
                return .run { [mode, isLinkLost, sessionClient, watchClient = watchConnectivityClient] _ in
                    let elapsed = sessionClient.incrementElapsed()
                    // Watch-primary: HK mirroring channel (per CLAUDE.md R2) — reliable
                    // when WC `reachable=false`. iPhone-standalone: WC path (no mirrored
                    // session exists in that mode, so HK channel is unavailable).
                    //
                    // Link down (IOS-00098-G): keep INCREMENTING (the counter is the tick
                    // payload — freezing it would rewind the Watch clock after reconnect,
                    // because Watch treats iPhone ticks as the source of truth) but skip
                    // the send — each attempt into a dead link costs a 3s timeout + retry.
                    if mode == .watchPrimary {
                        guard !isLinkLost else { return }
                        await sessionClient.sendLifecycleEventToWatch(.workoutTick(elapsedSeconds: elapsed))
                    } else {
                        await watchClient.sendWorkoutEvent(.workoutTick(elapsedSeconds: elapsed))
                    }
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
                // Skip vs. iPhone-initiated end:
                //   - sendWorkoutEvent(.workoutEnded): Watch initiated this end — no echo back needed.
                //     Watch's HRMirror is already dismissed via .delegate(.didFinishSaving).
                //   - sessionClient.endWorkout(): Watch already called session.end() — calling again
                //     on iPhone's mirrored session is redundant.
                //
                // Only transition iPhone UI to the finished screen. The Watch (primary owner)
                // shows the immediate summary; `.workoutSaved` is consumed by the app-level
                // listener in AppTabNewFeature for the plan link (IOS-00098-E).
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
                        await send(.sessionViewStateChange(.finishedOnWatch))
                    }
                )

            case .controls(.view(.endWorkoutButtonTapped)):
                // Mirroring link down (IOS-00098-G): the `.workoutEnded` send has no
                // route and state control is not queued after a disconnect — instead of
                // faking success, follow Apple's guidance and instruct the user to end
                // the workout on the Watch. The session stays alive; if the system
                // reconnects, End becomes functional again.
                if state.workoutMode == .watchPrimary, state.isWatchConnectionLost {
                    state.connectionLostAlert = AlertState {
                        TextState(String(localized: "Brak połączenia z Apple Watch"))
                    } actions: {
                        ButtonState(role: .cancel) {
                            TextState(String(localized: "OK"))
                        }
                    } message: {
                        TextState(String(localized: "Trening nadal trwa na zegarku. Zakończ go na Apple Watch, przytrzymując przycisk Stop."))
                    }
                    return .run { _ in
                        await WorkoutFileLogger.shared.log("[Connection] End tapped while link LOST — instruction alert shown")
                    }
                }

                let mode = state.workoutMode
                return .merge(
                    .cancel(id: SessionWatchCancelID.watchEventStream),
                    .cancel(id: SessionWatchCancelID.watchTickTimer),
                    .run { [mode,
                            watchClient = watchConnectivityClient,
                            sessionClient] send in
                        await WorkoutFileLogger.shared.log("STOPPED — ending workout")
                        // Watch-primary mode uses the HK mirroring channel — reliable even
                        // when WC is unreachable (fixes pre-existing iPhone-initiated End
                        // bug). iPhone-standalone keeps WC (no mirrored session exists).
                        if mode == .watchPrimary {
                            await sessionClient.sendLifecycleEventToWatch(.workoutEnded)
                        } else {
                            await watchClient.sendWorkoutEvent(.workoutEnded)
                        }
                        await WorkoutFileLogger.shared.log("END WORKOUT — calling sessionClient.endWorkout()")
                        await sessionClient.endWorkout()
                        await WorkoutFileLogger.shared.log("END WORKOUT — endWorkout() returned")
                        // Watch-primary: Watch shows the summary (primary owner) — iPhone only
                        // confirms the end. iPhone-standalone: iPhone owns the workout and
                        // presents the full summary from the router cache (IOS-00098-E).
                        if mode == .watchPrimary {
                            await send(.sessionViewStateChange(.finishedOnWatch))
                        } else {
                            await send(.sessionViewStateChange(.summary))
                        }
                    }
                    // Retry mechanism removed. HK channel does not require reachable=true,
                    // delivery is OS-managed through the mirrored workout session. The
                    // iPhone-standalone WC path remains best-effort — covered separately.
                )

            default:
                return .none
            }
        }
    }
}
