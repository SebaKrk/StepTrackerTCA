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

            case .watchEventReceived(.workoutSaved):
                guard state.sessionState == .summary else { return .none }
                return .send(.summary(.workoutSavedReceived))

            case .watchEventReceived:
                return .none

            case .hrReadingTimedOut:
                guard state.workoutMode == .iPhoneStandalone else { return .none }
                Logger.session.notice("hrReadingTimeout — no HR from Watch for 20s, resetting to 0")
                return .merge(
                    .run { [sessionClient] _ in sessionClient.resetWatchHeartRate() },
                    .send(.live(.resetHeartRate))
                )

            default:
                return .none
            }
        }
    }
}
