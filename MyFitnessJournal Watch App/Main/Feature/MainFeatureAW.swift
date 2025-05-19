//
//  MainFeatureAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//


import ComposableArchitecture
import Foundation

@Reducer
struct MainFeatureAW {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce { state, action in
                switch action {
                    
                case .binding(_):
                    return .none
                    
                //case let .tabChanged(tabItem):
                //    state.selectedTab = tabItem
                //    return .none
                    
                case let .view(.selectedWorkoutOption(item)):
                    return .send(.show(item))
                    
                case let .show(item):
                    switch item {
                    case .planned:
                        state.destination = .workoutSession(WorkoutSessionFeature.State())
                    case .mirroring:
                        print("mirroring")
                    case .scheduled:
                        print("scheduled")
                    case .free:
                        print("free")
                    }
                    return .none
                    
                case .destination:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
}


/// Implementation of `MainFeatureAW` action
extension MainFeatureAW {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        ///
        //case tabChanged(WorkoutOptionAW)
        
        case view(View)
        
        enum View {
            
            ///
            case selectedWorkoutOption(WorkoutOptionAW)
        }
        
        ///
        case show(WorkoutOptionAW)
        
        ///
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `MainFeatureAW` state
extension MainFeatureAW {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutTypes: [WorkoutOptionAW] = [.planned, .mirroring, .scheduled, .free]
        
        ///
        //var selectedTab: WorkoutOptionAW?
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
        
    }
    
}

/// Implementation of `MainFeatureAW` destination
extension MainFeatureAW {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutSessionFeature`.
        case workoutSession(WorkoutSessionFeature)
    }
    
}
