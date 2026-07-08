//
//  SessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import OSLog
import SharedModels
import HealthKit

@Reducer
struct SessionFeature {

    // MARK: - Dependency

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now

    @Dependency(\.dismiss) var dismiss

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        CombineReducers {
            // Order matters — earlier reducers may mutate state that later reducers
            // read. `lifecycleReducer` performs `setWorkoutMode` etc., which downstream
            // reducers depend on (e.g. `sessionPhaseReducer` reads `state.workoutMode`).
            lifecycleReducer
            sessionPhaseReducer
            controlsRoutingReducer
            watchEventsReducer
            intentsAndViewReducer
            joinLiveClassReducer
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$connectionLostAlert, action: \.connectionLostAlert)
        .ifLet(\.joinLiveClass, action: \.joinLiveClass) {
            JoinLiveClassFeature()
        }
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.live, action: \.live) {
            LiveSessionFeature()
        }
        Scope(state: \.controls, action: \.controls) {
            ControlsFeature()
        }
        Scope(state: \.summary, action: \.summary) {
            SummaryFeature()
        }
    }
}

