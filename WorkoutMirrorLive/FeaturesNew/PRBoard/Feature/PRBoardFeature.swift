//
//  PRBoardFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct PRBoardFeature {

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(.categoryTapped(category)):
                state.movementList = PRMovementListFeature.State(category: category)
                return .none

            case .view(.closeTapped):
                return .run { _ in await dismiss() }

            case .movementList:
                return .none
            }
        }
        .ifLet(\.$movementList, action: \.movementList) {
            PRMovementListFeature()
        }
    }
}
