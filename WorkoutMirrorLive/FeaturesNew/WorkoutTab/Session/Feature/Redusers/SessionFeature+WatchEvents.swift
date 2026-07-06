//
//  SessionFeature+WatchEvents.swift
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

    var watchEventsReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

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

            case .watchEventReceived(.workoutSaved(_)):
                // Plan link is consumed by the app-level listener (AppTabNewFeature,
                // IOS-00098-C). Here it matters only as scenario S4 (IOS-00098-G):
                // the Watch ended AND SAVED the workout while the mirroring link was
                // dead — mirrored `.ended` never arrived, but `.workoutSaved` came
                // through the WC queue. Close the session honestly.
                guard state.workoutMode == .watchPrimary,
                      state.sessionState == .session
                        || state.sessionState == .countdown
                        || state.sessionState == .waitingForWatch else { return .none }
                return .merge(
                    .run { _ in
                        await WorkoutFileLogger.shared.log("[Connection] .workoutSaved while session active — Watch ended remotely, closing session (S4)")
                    },
                    .send(.sessionViewStateChange(.finishedOnWatch))
                )

            case let .watchConnectionStatusChanged(status):
                switch status {
                case .lost:
                    guard state.sessionState == .session, !state.isWatchConnectionLost else { return .none }
                    state.isWatchConnectionLost = true
                    // Tick timer keeps RUNNING — the counter must not freeze (Watch treats
                    // iPhone ticks as its clock's source of truth; a frozen counter would
                    // rewind the Watch after reconnect). Sends are gated in `watchTickEffect`.
                    return .merge(
                        .send(.live(.setWatchConnectionLost(true))),
                        .run { _ in
                            await WorkoutFileLogger.shared.log("[Connection] LOST — banner shown, tick sends suspended (counter keeps running)")
                        }
                    )
                case .connected:
                    guard state.isWatchConnectionLost else { return .none }
                    state.isWatchConnectionLost = false
                    // Ticks resume flowing on the next timer beat — the counter kept
                    // counting through the outage, so the Watch clock stays consistent.
                    return .merge(
                        .send(.live(.setWatchConnectionLost(false))),
                        .run { _ in
                            await WorkoutFileLogger.shared.log("[Connection] RESTORED — banner cleared, tick sends resumed")
                        }
                    )
                }

            case .watchEventReceived:
                return .none

            default:
                return .none
            }
        }
    }
}
