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
                
            // Live Activity is now handled by child reducer via .liveActivity() action
                
            case .liveActivity:
                // Handled by Scope below
                return .none
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.startWorkoutMetricsStream)
                }
                
            // MARK: - Stopwatch
                
            case .view(.toggleStopwatch):
                state.isStopwatchVisible.toggle()
                
                // LiveActivity integration
                if state.isStopwatchVisible {
                    // Guard: don't start if already active
                    guard !state.liveActivity.timer.isActive else {
                        return .none
                    }
                    
                    // Showing stopwatch → start Timer LA (Coordinator will stop Workout LA)
                    let timerState = TimerActivityAttributes.ContentState(
                        heartRate: state.workoutMetrics.heartRate,
                        heartRateZone: state.currentHeartRateZone,
                        elapsedTime: state.stopwatchTime,
                        isRunning: state.isStopwatchRunning
                    )
                    return .send(.liveActivity(.timer(.start(timerName: "Stoper", initialState: timerState))))
                } else {
                    // Hiding stopwatch → stop Timer LA and restart Workout LA
                    let contentState = WorkoutSessionActivityAttributes.ContentState(
                        heartRate: state.workoutMetrics.heartRate,
                        heartRateZone: state.currentHeartRateZone,
                        heartRatePercentage: state.currentHeartRatePercentage,
                        activeEnergy: state.workoutMetrics.activeEnergy,
                        maxHeartRate: state.sessionMaxHeartRate,
                        averageHeartRate: state.sessionAverageHeartRate
                    )
                    return .merge(
                        .send(.liveActivity(.timer(.stop))),
                        .send(.liveActivity(.workout(.start(workoutName: "Workout", initialState: contentState))))
                    )
                }
                
                
            case .view(.startStopwatch):
                guard !state.isStopwatchRunning else { return .none }
                state.isStopwatchRunning = true
                
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(10)) {
                        await send(.internal(.stopwatchTick))
                    }
                }
                .cancellable(id: "stopwatchTimer")
                
            case .view(.stopStopwatch):
                guard state.isStopwatchRunning else { return .none }
                state.isStopwatchRunning = false
                return .cancel(id: "stopwatchTimer")
                
            case .view(.resetStopwatch):
                state.stopwatchTime = 0
                return .none
                
            case .internal(.stopwatchTick):
                state.stopwatchTime += 0.01
                return .none
            }
        }
        
        Scope(state: \.liveActivity, action: \.liveActivity) {
            LiveActivityFeature()
        }
    }
    
}


