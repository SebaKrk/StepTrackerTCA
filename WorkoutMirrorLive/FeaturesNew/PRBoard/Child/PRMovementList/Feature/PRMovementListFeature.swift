//
//  PRMovementListFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct PRMovementListFeature {

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(.movementTapped(movement)):
                state.detail = PRMovementDetailFeature.State(movement: movement)
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            PRMovementDetailFeature()
        }
    }
}
