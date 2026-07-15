//
//  SessionFeature+JoinLiveClass.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 2026-05-29.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension SessionFeature {

    var joinLiveClassReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .view(.joinLiveClassSheetDismissed):
                // Swipe-down / X — the broadcast CONTINUES, state stays alive.
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
                // Drop the class window origin — the next class starts a fresh window.
                state.classEntryZoneSnapshot = nil
                return .none

            case .joinLiveClass(.delegate(.joinedClass)):
                // Snapshot the effort origin on the FIRST join only — `joinedClass`
                // fires again on every reconnect, and resetting the baseline there
                // would zero out points earned before the drop.
                if state.classEntryZoneSnapshot == nil {
                    state.classEntryZoneSnapshot = state.live.effortPoints.secondsByZone
                }
                return .none

            case .joinLiveClass:
                return .none

            // Catch-all for `destination` presentation actions — composition happens
            // via `.ifLet(\.$destination, ...)` modifier on the body.
            case .destination(_):
                return .none

            // Terminal catch-alls for child feature actions whose state is handled
            // by their respective `Scope(state:action:)` reducers in the body.
            case .summary(.view(.endWorkoutButtonTapped)):
                return .none

            case .countDown(_):
                return .none

            case .live(.workoutMetrics), .live(.sensorFreshnessTick):
                // Bridge: feed the LiveSession effort counter into JoinLiveClass so
                // every BLE payload carries the athlete's CLASS points. Unlike the
                // on-screen counter (cumulative for the whole workout), the class
                // value is WINDOW-SCOPED: only effort since joining this class, so an
                // athlete who trained before it started enters the board at 0 like
                // everyone else. A one-tick lag vs the child reducer is harmless at 1 Hz.
                // `sensorFreshnessTick` included (IOS-00100-C): the stale flag can
                // flip without any metrics arriving (that's the point), and the
                // payloads must carry the truth from the next send on.
                // Read into locals first — reading `state.live` while mutating
                // `state.joinLiveClass` is an overlapping exclusive access.
                let windowPoints = state.classEntryZoneSnapshot.map {
                    EffortPointsScoring.points(from: state.live.effortPoints.secondsByZone, since: $0)
                } ?? 0
                let liveSensorStale = state.live.isSensorStale
                state.joinLiveClass?.currentEffortPoints = windowPoints
                state.joinLiveClass?.isSensorStale = liveSensorStale
                return .none

            case .live(_):
                return .none

            case .controls(_):
                return .none

            case .summary(_):
                return .none

            default:
                return .none
            }
        }
    }
}
