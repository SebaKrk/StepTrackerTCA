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
