//
//  WorkoutCreatorFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutCreatorFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Binding
            case .binding(_):
                return .none
                
                // MARK: - Action
                
                // MARK: - View Action
                
            case .view(.startButtonTaped):
                state.destination = .workoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case .view(.cancelButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
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

/// Implementation of `WorkoutDetailsFeature` action
extension WorkoutCreatorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case startButtonTaped
            ///
            case cancelButtonTapped
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutCreatorFeature` state
extension WorkoutCreatorFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var addDataDate: Date = .now
        
        // MARK: - Destination
        
        /// destination from WorkoutCreatorFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `WorkoutCreatorFeature` destination
extension WorkoutCreatorFeature {
    
    @Reducer
    enum Destination {
        case workoutMirroringView(WorkoutMirroringFeature)
    }
    
}


