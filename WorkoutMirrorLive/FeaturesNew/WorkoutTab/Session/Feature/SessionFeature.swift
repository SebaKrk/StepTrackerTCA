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

    /// EXPERIMENT (IOS-00100-D, DEBUG only): hold an app-side parallel BLE
    /// connection to the HR strap for the whole standalone session. On a drop the
    /// delegate issues a pending `connect()` (no timeout) — hypothesis: the system
    /// re-links the strap the moment it is back in range, instead of waiting for
    /// HealthKit's opaque internal retry (observed 3–39 min in the 2026-07-09 logs).
    /// Measure via `[Connection]` logs before promoting to release builds.
    #if DEBUG
    static let holdsStrapConnection = true
    #else
    static let holdsStrapConnection = false
    #endif

    // MARK: - Dependency

    @Dependency(\.sessionClient) var sessionClient
    @Dependency(\.maxHeartRateClient) var maxHeartRateClient
    @Dependency(\.personalDataClient) var personalDataClient
    @Dependency(\.watchConnectivityClient) var watchConnectivityClient
    @Dependency(\.bluetoothClient) var bluetoothClient
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
        .ifLet(\.$classActiveAlert, action: \.classActiveAlert)
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

