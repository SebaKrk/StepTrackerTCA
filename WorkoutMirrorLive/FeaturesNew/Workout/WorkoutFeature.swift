//
//  WorkoutFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct WorkoutFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.closeButtonTapped):
                return .run { send in
                    await self.dismiss()
                }
                
                
                
                // MARK: -
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `WorkoutFeature` action
extension WorkoutFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case closeButtonTapped
        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `WorkoutFeature` state
extension WorkoutFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from WorkoutFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `WorkoutFeature` destination
extension WorkoutFeature {
    
    @Reducer
    enum Destination {
        
    }
}

