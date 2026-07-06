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
    @Dependency(\.idleTimer) var idleTimer
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
            case let .setupMaxHeartRate(value):
                state.maxHeartRate = value
                return .none

            case let .setWatchConnectionLost(isLost):
                guard state.isWatchConnectionLost != isLost else { return .none }
                state.isWatchConnectionLost = isLost
                // Immediate LA push — with the link down no metrics update will arrive
                // to carry the flag, so push ContentState from the last known values.
                return .send(.liveActivity(.workout(.update(state.workoutContentState))))
                
            case let .workoutMetrics(data):
                // Watch is the primary HR source. When HealthKit sends HR = 0
                // (iPhone has no wrist sensor in this mode), preserve the last
                // known value so Watch readings are not overwritten.
                let effectiveHR = data.heartRate > 0 ? data.heartRate : state.workoutMetrics.heartRate
                if effectiveHR > 0 {
                    state.hrBuffer.append(State.HRSample(date: Date(), bpm: effectiveHR))
                }
                state.workoutMetrics = WorkoutMetrics(
                    averageHeartRate: data.averageHeartRate,
                    heartRate: effectiveHR,
                    activeEnergy: data.activeEnergy
                )
                if effectiveHR > 0 {
                    Task { await WorkoutFileLogger.shared.logHRIfNeeded(bpm: effectiveHR) }
                }
                // state.workoutMetrics updated above — the computed property assembles
                // ContentState from a single source (no manual duplication of the field list).
                let contentState = state.workoutContentState

                var effects: [Effect<Action>] = [
                    .send(.calculateHeartRateZone(Int(effectiveHR), state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(Int(effectiveHR), state.maxHeartRate)),
                    .send(.liveActivity(.workout(.update(contentState))))
                ]

                // Update session stats only when we have a real reading.
                // Skipping HealthKit zeros prevents them from skewing AVG HR.
                if data.heartRate > 0 {
                    effects.append(.send(.calculateSessionHeartRateStats(Int(effectiveHR))))
                }

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
                
            case .resetHeartRate:
                let current = state.workoutMetrics
                state.workoutMetrics = WorkoutMetrics(
                    averageHeartRate: current.averageHeartRate,
                    heartRate: 0,
                    activeEnergy: current.activeEnergy
                )
                return .merge(
                    .send(.calculateHeartRateZone(0, state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(0, state.maxHeartRate))
                )

            case .startWorkoutMetricsStream:
                return .run { send in
                    for await metric in await client.workoutMetricsStream() {
                        await send(.workoutMetrics(metric))
                    }
                }
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { [idleTimer] send in
                    await idleTimer.setDisabled(true)
                    await send(.startWorkoutMetricsStream)
                }

            case .view(.viewDidDisappear):
                return .run { [idleTimer] _ in
                    await idleTimer.setDisabled(false)
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


