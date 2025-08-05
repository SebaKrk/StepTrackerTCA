//
//  WorkoutSessionFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutSessionFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .workoutViewStateChange(viewState):
                state.workoutSessionState = viewState
                return .none
                
                // MARK: - View Action
            case let .view(.changeViewState(viewState)):
                return .send(.workoutViewStateChange(viewState))
                
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Child
            case .countDown(.closeView):
                return .send(.workoutViewStateChange(.session))
//                return .none
            default:
                return .none
            }
        }
        Scope(state: \.countDown, action: \.countDown) {
            CountDownFeature()
        }
        Scope(state: \.mirroring, action: \.mirroring) {
            WorkoutMirroringFeature()
        }
    }
}

/// Implementation of `WorkoutSessionFeature` action
extension WorkoutSessionFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        case workoutViewStateChange(WorkoutSessionState)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case changeViewState(WorkoutSessionState)
        }
        
        // MARK: - Child
        
        ///
        case countDown(CountDownFeature.Action)
        
        ///
        case mirroring(WorkoutMirroringFeature.Action)
    }
    
    
}

/// Implementation of `WorkoutSessionFeature` state
extension WorkoutSessionFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var workoutSessionState: WorkoutSessionState = .start
        
        var selectedWorkout: WorkoutType?
        
        // MARK: - Child

        ///
        var countDown: CountDownFeature.State = .init()
        
        ///
        var mirroring: WorkoutMirroringFeature.State = .init()
    }
    
}

