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
                
                return .merge(
                    .send(.calculateHeartRateZone(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateSessionHeartRateStats(Int(data.heartRate))),
                    .send(.liveActivity(.workout(.update(contentState))))
                )
                
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
                
            case let .view(.stopwatch(action)):
                return .send(.stopwatch(.view(action)))
                
                // MARK: - Stopwatch Delegate
                
            case .stopwatch(.delegate(.didToggleVisibility)):
                if state.stopwatch.isVisible {
                    // Guard: don't start if already active
                    guard !state.liveActivity.timer.isActive else { return .none }
                    
                    // Showing stopwatch → start Timer LA (Coordinator will stop Workout LA)
                    return .send(.liveActivity(.timer(.start(timerName: "Stoper", initialState: state.timerContentState))))
                } else {
                    // Hiding stopwatch → stop Timer LA and restart Workout LA
                    return .merge(
                        .send(.liveActivity(.timer(.stop))),
                        .send(.liveActivity(.workout(.start(workoutName: "Workout", initialState: state.workoutContentState))))
                    )
                }
          
                // MARK: - Child
            case .liveActivity:
                return .none
                
            case .stopwatch:
                return .none
            }
        }
        Scope(state: \.liveActivity, action: \.liveActivity) {
            LiveActivityFeature()
        }
        Scope(state: \.stopwatch, action: \.stopwatch) {
            StopwatchFeature()
        }
    }
    
}


