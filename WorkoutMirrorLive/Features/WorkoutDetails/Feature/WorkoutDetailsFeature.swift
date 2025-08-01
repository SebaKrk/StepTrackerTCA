//
//  WorkoutDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 01/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutDetailsFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.startWorkoutButtonTapped):
                // tu narazie otwieram Mirroring dla testow nawigacji bez przekazania itemu
                state.destination = .openWorkoutMirroringView(WorkoutMirroringFeature.State())
                return .none
            case .view(.viewDidAppear):
                return .none
                
                // MARK:
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `WorkoutDetailsFeature` action
extension WorkoutDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case startWorkoutButtonTapped
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutDetailsFeature` state
extension WorkoutDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workout: String
        
        // MARK: - Destination
        
        /// destination from WorkoutDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `WorkoutDetailsFeature` destination
extension WorkoutDetailsFeature {
    
    @Reducer
    enum Destination {
        case openWorkoutMirroringView(WorkoutMirroringFeature)
    }
    
}
