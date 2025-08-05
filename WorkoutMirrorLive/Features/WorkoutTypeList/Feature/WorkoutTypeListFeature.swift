//
//  WorkoutTypeListFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 04/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutTypeListFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
            case let .selectedWorkout(workout):
                state.selectedWorkout = workout
                if let workout {
                    state.destination = .workoutSessionView(WorkoutSessionFeature.State(selectedWorkout: workout))
                }
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
                // MARK: - Destination
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `WorkoutTypeListFeature` action
extension WorkoutTypeListFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case selectedWorkout(WorkoutType?)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutTypeListFeature` state
extension WorkoutTypeListFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var workoutTypes: [WorkoutType] = [.boxing, .cross, .functional]
        
        var selectedWorkout: WorkoutType?
 
        // MARK: - Destination
        
        /// destination from WorkoutTypeListFeature
        @Presents var destination: Destination.State?
    }
    
}


/// Implementation of `WorkoutTypeListFeature` destination
extension WorkoutTypeListFeature {
    
    @Reducer
    enum Destination {
        
        case workoutSessionView(WorkoutSessionFeature)
    }
    
}




