//
//  SessionFeature+ViewActions.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

extension SessionFeature {

    var intentsAndViewReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // App Intents from Live Activity / Lock Screen — routed to the same flow
            // as the on-screen control buttons.

            case .intentPauseRequested:
                // Only react when currently running — ignore if already paused or session ended.
                guard state.controls.sessionState == .running else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .intentResumeRequested:
                guard state.controls.sessionState == .paused else { return .none }
                return .send(.controls(.view(.mainControlButtonTapped)))

            case .intentEndRequested:
                guard state.sessionState == .session else { return .none }
                return .send(.controls(.view(.endWorkoutButtonTapped)))

            // View actions — small, state-only mutations.

            case .view(.heartRateZoneButtonTapped):
                state.destination = .openHeartRateZoneInfo(HeartRateZoneInfoFeature.State())
                return .none

            case .view(.timerButtonTapped):
                return .send(.live(.userStopwatch(.view(.toggleVisibility))))

            case .view(.joinLiveClassToolbarButtonTapped):
                // Tap ikony obok HR zones: utwórz state przy pierwszym tap'ie, pokaż sheet.
                // Kolejne tapy: state istnieje (broadcast trwa) — tylko pokaż sheet.
                if state.joinLiveClass == nil {
                    var newState = JoinLiveClassFeature.State()
                    newState.maxHeartRate = state.live.maxHeartRate
                    state.joinLiveClass = newState
                }
                state.isJoinLiveClassSheetPresented = true
                return .none

            default:
                return .none
            }
        }
    }
}
