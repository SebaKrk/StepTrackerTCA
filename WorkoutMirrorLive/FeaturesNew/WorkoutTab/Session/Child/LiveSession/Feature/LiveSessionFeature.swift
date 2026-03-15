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
                
                // MARK: - User Stopwatch Delegate

            case .userStopwatch(.delegate(.didToggleVisibility)):
                if state.userStopwatch.isVisible {
                    // Mutual exclusion: block if phase stopwatch is managing
                    if state.phaseStopwatch.isManagingPhase {
                        state.userStopwatch.isVisible = false
                        return .none
                    }
                    state.phasePanel?.isTimerButtonDisabled = true
                    guard !state.liveActivity.timer.isActive else { return .none }
                    return .send(.liveActivity(.timer(.start(timerName: "Stoper", initialState: state.timerContentState))))
                } else {
                    state.phasePanel?.isTimerButtonDisabled = false
                    return .merge(
                        .send(.liveActivity(.timer(.stop))),
                        .send(.liveActivity(.workout(.start(workoutName: "Workout", initialState: state.workoutContentState))))
                    )
                }

            case .userStopwatch(.delegate(.didStart)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case .userStopwatch(.delegate(.didStop)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case .userStopwatch(.delegate(.didReset)):
                return .send(.liveActivity(.timer(.update(state.timerContentState))))

            case let .liveActivity(.timer(.activityUpdated(newState))):
                if newState.isRunning && !state.userStopwatch.isRunning {
                    return .send(.userStopwatch(.view(.start)))
                } else if !newState.isRunning && state.userStopwatch.isRunning {
                    return .send(.userStopwatch(.view(.stop)))
                }
                return .none

            case .liveActivity(.timer(.activityStopped)):
                return .merge(
                    .send(.userStopwatch(.view(.stop))),
                    .send(.userStopwatch(.view(.setVisibility(false))))
                )

            case .userStopwatch:
                return .none

                // MARK: - Phase Stopwatch Delegate

            case .phaseStopwatch(.delegate(.returnToPhaseTimerRequested)):
                guard state.phaseStopwatch.isManagingPhase else { return .none }
                var effects: [Effect<Action>] = [
                    .send(.phaseStopwatch(.view(.stop))),
                    .send(.phaseStopwatch(.view(.setVisibility(false))))
                ]
                effects += syncPhaseStopwatchToPhasePanel(state: &state)
                return .merge(effects)

            case .phaseStopwatch:
                return .none

            case .liveActivity:
                return .none

                // MARK: - Phase Panel

            case let .setupPhasePanel(phases):
                state.phasePanel = phases.isEmpty ? nil : PhasePanelFeature.State(phases: phases)
                return .none

            case let .phasePanel(.delegate(.timerManagementRequested(elapsed))):
                // Mutual exclusion: block if user stopwatch is already visible
                guard !state.userStopwatch.isVisible else { return .none }
                let wasRunning = state.phasePanel?.timerRunning ?? false
                state.phasePanel?.timerRunning = false
                state.phaseStopwatch.isManagingPhase = true
                state.phaseStopwatch.time = TimeInterval(elapsed)
                var effects: [Effect<Action>] = [
                    .cancel(id: PhasePanelFeatureCancelID.timer),
                    .send(.phaseStopwatch(.view(.setVisibility(true))))
                ]
                if wasRunning {
                    effects.append(.send(.phaseStopwatch(.view(.start))))
                }
                return .merge(effects)

            case .phasePanel:
                return .none
            }
        }
        Scope(state: \.liveActivity, action: \.liveActivity) {
            LiveActivityFeature()
        }
        Scope(state: \.userStopwatch, action: \.userStopwatch) {
            StopwatchFeature(id: StopwatchID.user)
        }
        Scope(state: \.phaseStopwatch, action: \.phaseStopwatch) {
            StopwatchFeature(id: StopwatchID.phase)
        }
        .ifLet(\.phasePanel, action: \.phasePanel) {
            PhasePanelFeature()
        }
    }

    // MARK: - Helpers

    /// Syncs elapsed time and running state from phaseStopwatch back to the phase panel.
    /// Clears `isManagingPhase`. Returns any additional phase-panel effects needed.
    private func syncPhaseStopwatchToPhasePanel(state: inout State) -> [Effect<Action>] {
        let syncedElapsed = Int(state.phaseStopwatch.time)
        let wasRunning = state.phaseStopwatch.isRunning
        state.phasePanel?.elapsedSeconds = syncedElapsed
        state.phasePanel?.timerRunning = wasRunning
        state.phaseStopwatch.isManagingPhase = false
        guard wasRunning else { return [] }
        return [.send(.phasePanel(.timerTick))]
    }

}


