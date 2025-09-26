//
//  LiveSessionFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct LiveSessionFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.sessionClient) var client
    @Dependency(\.sessionCalculations) var calculation
     
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
                    .send(.calculateSessionHeartRateStats(Int(data.heartRate)))
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
    }
    
}
