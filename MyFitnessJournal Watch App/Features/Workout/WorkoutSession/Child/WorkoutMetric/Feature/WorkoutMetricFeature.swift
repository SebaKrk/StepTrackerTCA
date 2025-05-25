//
//  WorkoutMetricFeature.swift
//  MyFitnessJournal Watch App
//
//  Created by Sebastian Sciuba on 22/05/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutMetricFeature {
    
    // MARK: - Properties
    
    var service: WorkoutMetricService
    
    // MARK: - Lifecycle
    
    init(service: WorkoutMetricService = DefaultWorkoutMetricService()) {
        self.service = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                    // MARK: - Binding
                case .binding(_):
                    return .none
                    
                    // MARK: - Actions
                case let .workoutMetrics(data):
                    state.workoutMetrics = data
                    return .none
                    
                    // MARK: - View Actions
                case .view(.startHeartAnimation):
                    state.animateHeart = true
                    return .run { send in
                        for await value in service.workoutMetricsStream {
                            await send(.workoutMetrics(value))
                        }
                    }
                }
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMetricFeature` state
extension WorkoutMetricFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        ///
        case workoutMetrics(WorkoutMetrics)
        
        // MARK: - View Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            case startHeartAnimation
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMetricFeature` state
extension WorkoutMetricFeature {
    @ObservableState
    struct State: Equatable {
        
        var elapsedTime: TimeInterval = 0

//        var averageHeartRate: Double = 0
//        
//        var heartRate: Double = 0
//        
//        var activeEnergy: Double = 0
        
        var animateHeart: Bool = false
        
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
    }
}
