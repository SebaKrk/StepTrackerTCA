//
//  PRMovementDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/08/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct PRMovementDetailFeature {

    @ObservableState
    struct State: Equatable {
        let movement: PRMovement
    }

    // No actions in S-01 — the screen is read-only until entries arrive (S-02).
    enum Action {}

    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
