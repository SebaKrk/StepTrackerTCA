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
    @Dependency(\.liveActivityClient) var liveActivityClient
     
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
                return .merge(
                    .send(.calculateHeartRateZone(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateHeartRatePercentage(Int(data.heartRate), state.maxHeartRate)),
                    .send(.calculateSessionHeartRateStats(Int(data.heartRate))),
                    .send(.updateLiveActivity)
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
                
                // MARK: - Live Activity Actions
                
            case let .startLiveActivity(workoutName):
                let initialState = WorkoutSessionActivityAttributes.ContentState(
                    heartRate: state.workoutMetrics.heartRate,
                    heartRateZone: state.currentHeartRateZone,
                    heartRatePercentage: state.currentHeartRatePercentage,
                    activeEnergy: state.workoutMetrics.activeEnergy,
                    maxHeartRate: state.sessionMaxHeartRate,
                    averageHeartRate: state.sessionAverageHeartRate
                )
                
                return .run { send in
                    do {
                        let activityId = try await liveActivityClient.start(workoutName, initialState)
                        await send(.liveActivityStarted(activityId))
                    } catch {
                        print("❌ Failed to start Live Activity: \(error)")
                    }
                }
                
            case let .liveActivityStarted(activityId):
                state.liveActivityId = activityId
                return .none
                
            case .updateLiveActivity:
                guard let activityId = state.liveActivityId else {
                    return .none
                }
                
                let newState = WorkoutSessionActivityAttributes.ContentState(
                    heartRate: state.workoutMetrics.heartRate,
                    heartRateZone: state.currentHeartRateZone,
                    heartRatePercentage: state.currentHeartRatePercentage,
                    activeEnergy: state.workoutMetrics.activeEnergy,
                    maxHeartRate: state.sessionMaxHeartRate,
                    averageHeartRate: state.sessionAverageHeartRate
                )
                
                return .run { _ in
                    do {
                        try await liveActivityClient.update(activityId, newState)
                    } catch {
                        print("❌ Failed to update Live Activity: \(error)")
                    }
                }
                
            case .stopLiveActivity:
                guard let activityId = state.liveActivityId else {
                    return .none
                }
                
                return .run { send in
                    do {
                        try await liveActivityClient.stop(activityId)
                        await send(.liveActivityStopped)
                    } catch {
                        print("❌ Failed to stop Live Activity: \(error)")
                    }
                }
                
            case .liveActivityStopped:
                state.liveActivityId = nil
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.startWorkoutMetricsStream)
                }
            }
        }
    }
    
}

/// Implementation of `LiveSessionFeature` action
extension LiveSessionFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions

        /// Updates the current workout metrics with new data.
        /// Triggered whenever a new `WorkoutMetrics` is received from the workout stream.
        case workoutMetrics(WorkoutMetrics)
        
        /// Sets the maximum heart rate (HR max) for the current session.
        /// Usually calculated at the beginning of the session using age and sex.
        case setupMaxHeartRate(Int)
        
        /// Starts streaming workout metrics (heart rate, active energy, etc.) from the session client.
        case startWorkoutMetricsStream
        
        /// Calculates the current heart rate zone based on the latest heart rate and HR max.
        case calculateHeartRateZone(Int, Int)
        
        /// Calculates the user's current heart rate as a percentage of the HR max.
        case calculateHeartRatePercentage(Int, Int)
        
        /// Updates the session's average and maximum heart rate with the provided values.
        case updateSessionHeartRateStats(average: Int, max: Int)

        /// Calculates session-level heart rate statistics based on a new heart rate reading.
        case calculateSessionHeartRateStats(Int)
        
        // MARK: - Live Activity Actions
        
        /// Starts a new Live Activity for the workout session
        case startLiveActivity(String)
        
        /// Called when Live Activity is successfully started
        case liveActivityStarted(String)
        
        /// Updates the Live Activity with current workout metrics
        case updateLiveActivity
        
        /// Stops the Live Activity
        case stopLiveActivity
        
        /// Called when Live Activity is successfully stopped
        case liveActivityStopped
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
        }
    }
}

/// Implementation of `LiveSessionFeature` state
extension LiveSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The current metrics of the workout, such as heart rate and active energy burned.
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
        /// The currently calculated heart rate zone for the user, based on HR max and current HR.
        var currentHeartRateZone: HeartRateZone = .resting

        /// The user's current heart rate as a percentage of the maximum heart rate.
        var currentHeartRatePercentage: Int = 0

        /// The average heart rate calculated across the current session.
        var sessionAverageHeartRate: Int = 0

        /// The maximum heart rate recorded so far in the current session.
        var sessionMaxHeartRate: Int = 0

        /// The maximum heart rate (HR max) calculated at the beginning of the session.
        /// Provided by `SessionFeature`, which retrieves the user’s age and biological sex
        /// from `personCalculatorClient` and applies the appropriate calculation strategy.
        var maxHeartRate: Int = 0
        
        /// The ID of the active Live Activity. Nil if no Live Activity is running.
        var liveActivityId: String?
    }
    
}
