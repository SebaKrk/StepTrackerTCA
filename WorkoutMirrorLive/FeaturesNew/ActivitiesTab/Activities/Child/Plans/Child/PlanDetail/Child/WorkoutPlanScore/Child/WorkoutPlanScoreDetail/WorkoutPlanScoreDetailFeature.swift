//
//  WorkoutPlanScoreDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 08/03/2026.
//

import ComposableArchitecture
import SharedModels

@Reducer
struct WorkoutPlanScoreDetailFeature {

    // MARK: - State

    @ObservableState
    struct State {
        var score: WorkoutPlanScore
    }

    // MARK: - Action

    enum Action {}

    // MARK: - Body

    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
