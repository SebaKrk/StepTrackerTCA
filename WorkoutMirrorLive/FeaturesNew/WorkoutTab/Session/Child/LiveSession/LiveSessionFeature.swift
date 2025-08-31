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
                
            case .setupMaxHeartRate:
                state.maxHeartRate = calculation.calculateMaxHeartRate(state.userAge, state.userGender)
                return .run { send in
                    for await metric in client.workoutMetricsStream() {
                        await send(.workoutMetrics(metric))
                    }
                }
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.setupMaxHeartRate)
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
        ///
        /// - Parameter data: The latest workout metrics from the session.
        case workoutMetrics(WorkoutMetrics)
        
        ///
        case setupMaxHeartRate
        
        ///
        case calculateHeartRateZone(Int,Int)
        
        ///
        case calculateHeartRatePercentage(Int,Int)
        
        ///
        case updateSessionHeartRateStats(average: Int, max: Int)

        ///
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
        
        ///
        var currentHeartRateZone: HeartRateZone = .resting
        
        ///
        var currentHeartRatePercentage: Int = 0
        
        ///
        var sessionAverageHeartRate: Int = 0
        
        ///
        var sessionMaxHeartRate: Int = 0
        
        ///
        var maxHeartRate: Int = 0
        
        // TODO: - WYCIAGNIJ TE DANE Z HELHKIT
        ///
        var userAge: Int = 38
        
        ///
        var userGender: Gender? = .male
    }
    
}
