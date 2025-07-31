//
//  LiveFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 31/07/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LiveFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.startWorkoutMirror):
                state.destination = .openWorkoutMirroringView(WorkoutMirroringFeature.State())
                return .none
                
            case .view(.viewDidAppear):
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `LiveFeature` action
extension LiveFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            ///
            case startWorkoutMirror
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `LiveFeature` state
extension LiveFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
//        var isWorkoutMirrorOpen: Bool = false
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `LiveFeature` destination
extension LiveFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `WorkoutMirroringFeature`.
        case openWorkoutMirroringView(WorkoutMirroringFeature)
    }
}

