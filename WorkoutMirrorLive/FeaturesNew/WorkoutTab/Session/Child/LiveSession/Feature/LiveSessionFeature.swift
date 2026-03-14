//
//  LiveSessionFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

@Reducer
struct LiveSessionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.sessionClient) var client
    @Dependency(\.sessionCalculations) var calculation
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .setupMaxHeartRate(value):
                state.maxHeartRate = value
                return .none
                
            case let .workoutMetrics(data):
                state.workoutMetrics = data
                // Delegate Live Activity update to child reducer
                let contentState = WorkoutSessionActivityAttributes.ContentState(
                    heartRate: data.heartRate,
                    heartRateZone: state.currentHeartRateZone,
                    heartRatePercentage: state.currentHeartRatePercentage,
                    activeEnergy: data.activeEnergy,
                    maxHeartRate: state.sessionMaxHeartRate,
                    averageHeartRate: state.sessionAverageHeartRate
                )
                
                var effects: [Effect<Action>] = [
                    .send(.calculateHeartRateZone(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateSessionHeartRateStats(Int(data.heartRate))),
                    .send(.liveActivity(.workout(.update(contentState))))
                ]
                
                if state.liveActivity.timer.isActive {
                    effects.append(.send(.liveActivity(.timer(.update(state.timerContentState)))))
                }
                
                return .merge(effects)
                
            case let .calculateSessionHeartRateStats(heartRate):
                return .run { send in
                    let (average, max) = await calculation.processHeartRate(heartRate)
                    await send(.updateSessionHeartRateStats(average: average, max: max))
                }
                
            case let .calculateHeartRateZone(heartRate, maxHR):
                state.currentHeartRateZone = calculation.calculateHeartRateZone(Int(heartRate), maxHR)
                return .none
                
            case let .calculateHeartRatePercentage(heartRate, maxHR):
                state.currentHeartRatePercentage = calculation.calculateHeartRatePercentage(Int(heartRate), maxHR)
                return .none
                
            case let .updateSessionHeartRateStats(average, max):
                state.sessionAverageHeartRate = average
                state.sessionMaxHeartRate = max
                return .none
                
            case .startWorkoutMetricsStream:
                return .run { send in
                    for await metric in await client.workoutMetricsStream() {
                        await send(.workoutMetrics(metric))
                    }
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.startWorkoutMetricsStream)
                }
                
                // MARK: - Stopwatch Delegate
                
            case .stopwatch(.delegate(.didToggleVisibility)):
                if state.stopwatch.isVisible {
                    // Guard: don't start if already active
                    guard !state.liveActivity.timer.isActive else { return .none }

                    // Showing stopwatch → start Timer LA (Coordinator will stop Workout LA)
                    return .send(.liveActivity(.timer(.start(timerName: "Stoper", initialState: state.timerContentState))))
                } else {
                    // Hiding stopwatch → stop Timer LA and restart Workout LA
                    var effects: [Effect<Action>] = [
                        .send(.liveActivity(.timer(.stop))),
                        .send(.liveActivity(.workout(.start(workoutName: "Workout", initialState: state.workoutContentState))))
                    ]
                    // If stopwatch was managing the phase timer, sync and resume on hide
                    if state.stopwatch.isManagingPhase {
                        let syncedElapsed = Int(state.stopwatch.time)
                        let wasRunning = state.stopwatch.isRunning
                        state.phasePanel?.elapsedSeconds = syncedElapsed
                        state.phasePanel?.timerRunning = wasRunning
                        state.stopwatch.isManagingPhase = false
                        if wasRunning {
                            effects.append(.send(.phasePanel(.timerTick)))
                        }
                    }
                    return .merge(effects)
                }
                
            case .stopwatch(.delegate(.didStart)):
                print("🏁 [LiveSessionFeature] Stopwatch started -> Updating LA")
                return .send(.liveActivity(.timer(.update(state.timerContentState))))
                
            case .stopwatch(.delegate(.didStop)):
                print("🛑 [LiveSessionFeature] Stopwatch stopped -> Updating LA")
                return .send(.liveActivity(.timer(.update(state.timerContentState))))
                
            case .stopwatch(.delegate(.didReset)):
                print("🔄 [LiveSessionFeature] Stopwatch reset -> Updating LA")
                return .send(.liveActivity(.timer(.update(state.timerContentState))))
                
            case let .liveActivity(.timer(.activityUpdated(newState))):
                // Prevent redundant updates that cause feedback loops or HK errors
                if newState.isRunning && !state.stopwatch.isRunning {
                    print("🔄 [LiveSessionFeature] Syncing from Live Activity: START")
                    return .send(.stopwatch(.view(.start)))
                } else if !newState.isRunning && state.stopwatch.isRunning {
                    print("🔄 [LiveSessionFeature] Syncing from Live Activity: STOP")
                    return .send(.stopwatch(.view(.stop)))
                }
                return .none
                
            case .liveActivity(.timer(.activityStopped)):
                print("🛑 [LiveSessionFeature] Live Activity killed -> Stopping and Hiding stopwatch")
                // If the activity was killed (swiped or Stop button), ensure stopwatch stops in UI AND hides
                return .merge(
                    .send(.stopwatch(.view(.stop))),
                    .send(.stopwatch(.view(.setVisibility(false))))
                )
                
            case .stopwatch(.delegate(.returnToPhaseTimerRequested)):
                guard state.stopwatch.isManagingPhase else { return .none }
                let syncedElapsed = Int(state.stopwatch.time)
                let wasRunning = state.stopwatch.isRunning
                state.phasePanel?.elapsedSeconds = syncedElapsed
                state.phasePanel?.timerRunning = wasRunning
                state.stopwatch.isManagingPhase = false
                var effects: [Effect<Action>] = [
                    .send(.stopwatch(.view(.stop))),
                    .send(.stopwatch(.view(.setVisibility(false))))
                ]
                if wasRunning {
                    effects.append(.send(.phasePanel(.timerTick)))
                }
                return .merge(effects)

            case .liveActivity:
                return .none

            case .stopwatch:
                return .none

                // MARK: - Phase Panel

            case let .setupPhasePanel(phases):
                state.phasePanel = phases.isEmpty ? nil : PhasePanelFeature.State(phases: phases)
                return .none

            case let .phasePanel(.delegate(.timerManagementRequested(elapsed))):
                let wasRunning = state.phasePanel?.timerRunning ?? false
                state.phasePanel?.timerRunning = false
                state.stopwatch.isManagingPhase = true
                state.stopwatch.time = TimeInterval(elapsed)
                var effects: [Effect<Action>] = [
                    .cancel(id: PhasePanelFeatureCancelID.timer),
                    .send(.stopwatch(.view(.setVisibility(true))))
                ]
                if wasRunning {
                    effects.append(.send(.stopwatch(.view(.start))))
                }
                return .merge(effects)

            case .phasePanel:
                return .none
            }
        }
        Scope(state: \.liveActivity, action: \.liveActivity) {
            LiveActivityFeature()
        }
        Scope(state: \.stopwatch, action: \.stopwatch) {
            StopwatchFeature()
        }
        .ifLet(\.phasePanel, action: \.phasePanel) {
            PhasePanelFeature()
        }
    }
    
}


