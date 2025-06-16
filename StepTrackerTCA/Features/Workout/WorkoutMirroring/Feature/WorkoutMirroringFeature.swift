//
//  WorkoutMirroringFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

@Reducer
struct WorkoutMirroringFeature {
    
    // MARK: - Dependency
    
    
    @Dependency(\.trainingManager) var manager
    
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
                    print(data.heartRate)
                    return .none
                    
                    // MARK: - View Actions
                case .view(.viewDidAppear):
                    return .run { send in
                        for await metrics in manager.workoutMetricsStream {
                            await send(.workoutMetrics(metrics))
                        }
                    }
                    
                case .view(.viewWillDisappear):
                    return .cancel(id: CancelID.workoutMetricsStream)
                }
            }
        }
    }
    
    private enum CancelID {
        case workoutMetricsStream
    }
}

import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMirroringFeature` action
extension WorkoutMirroringFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Actions
        
        case workoutMetrics(WorkoutMetrics)
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// The action when view will disappear to clean up resources
            case viewWillDisappear
            
        }
    }
    
}

import ComposableArchitecture
import SwiftUI

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        var workoutMetrics: WorkoutMetrics = WorkoutMetrics(
            averageHeartRate: 0,
            heartRate: 0,
            activeEnergy: 0
        )
        
    }
}
