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
                // UUID payload will be consumed in Sub-D — for now Summary still uses
                // polling fallback. Keep exhaustive switch happy.
                guard state.sessionState == .summary else { return .none }
                return .send(.summary(.workoutSavedReceived))

            case .watchEventReceived:
                return .none

            default:
                return .none
            }
        }
    }
}
