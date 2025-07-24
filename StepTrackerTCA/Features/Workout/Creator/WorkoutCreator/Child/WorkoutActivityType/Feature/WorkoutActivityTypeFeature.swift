//
//  WorkoutActivityTypeFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 18/07/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct WorkoutActivityTypeFeature {
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Internal Actions
            //case let .internalAction(.workoutActivityTypeChange(type)):
            case let .workoutActivityTypeChange(type):
                state.workoutActivityType = type
                return .none
                
                // MARK: - View Actions
            case .view(.saveButtonTapped):
                return .run { [update = state.workoutActivityType] send in
                    if let update = update as? WorkoutActivityType {
                        await send(.delegate(.workoutActivityTypeUpdated(update)))
                    }
                }
                
                // MARK: - Delegate Actions
            case .delegate(_):
                return .none
            }
        }
    }
    
}
// MARK: - Action

/// Implementation of `WorkoutActivityTypeFeature` action
extension WorkoutActivityTypeFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        case binding(BindingAction<State>)
        case view(View)
        case internalAction(InternalAction)
        case delegate(DelegateAction)
        
        // MARK: - Internal Action
        
        case workoutActivityTypeChange(WorkoutActivityType?)
        
        @CasePathable
        enum InternalAction: Equatable {
            
        }
        
        // MARK: - View actions
        enum View: Equatable {
            case saveButtonTapped
        }
        
        // MARK: - Delegate Action
        enum DelegateAction: Equatable {
            case workoutActivityTypeUpdated(WorkoutActivityType)
        }
        
    }
}

// MARK: - State

/// Implementation of `WorkoutActivityTypeFeature` state
extension WorkoutActivityTypeFeature {
    
    @ObservableState
    struct State {
        
        // MARK: Properties
        
        /// Selected workout activity type (e.g., crossTraining, running, cycling)
        var workoutActivityType: WorkoutActivityType?
        //= .crossTraining
        
        
        /// Available workout activity types for selection
        var availableWorkoutTypes: [WorkoutActivityType] = [.crossTraining, .boxing]
        
    }
    
}
