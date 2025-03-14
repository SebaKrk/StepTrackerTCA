//
//  ScoresFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/03/2025.
//

protocol ScoresFeatureServices {
    
}


final class DefaultScoresFeatureServices: ScoresFeatureServices {
    
}

import ComposableArchitecture
import Foundation

@Reducer
struct ScoresFeature {
    
    // MARK: - Dependencies
    
    let services: ScoresFeatureServices
    
    // MARK: - Livecycle
    
    init(service: ScoresFeatureServices = DefaultScoresFeatureServices()) {
        self.services = service
    }
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state,action in
            switch action {
                // MARK: - Action
                
            case .updateWorkout:
                let selectedWorkout = state.selectedWorkout
                dump(selectedWorkout)
                return .none
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    await send(.updateWorkout)
                }
                
                // MARK: - Destination
            case .destination:
                return .none
            }
        }
        
        .ifLet(\.$destination, action: \.destination)
    }
}

import ComposableArchitecture
import Foundation

/// Defines the actions available in `ScoresFeature`, handling data fetching,
/// state updates, and user interactions.
extension ScoresFeature {
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        case updateWorkout
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
    
    
import ComposableArchitecture
import Foundation
    
    /// Represents the state for `ScoresFeature`
extension ScoresFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var selectedWorkout: NewGroupedWorkouts

        
        // MARK: - Destination
        
        /// Represents the navigation destination state within `SummaryFeature`.
        @Presents var destination: Destination.State?
    }
    
}


import ComposableArchitecture
import Foundation

/// Implementation of `ScoresFeature` destination
extension ScoresFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ScoresFeature`.
        //case open(ScoreFeature)
    }
    
}

import ComposableArchitecture
import SwiftUI

@ViewAction(for: ScoresFeature.self)
struct ScoresView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<ScoresFeature>
    // MARK: - View
    
    var body: some View {
        Group {
            Text(store.selectedWorkout.workoutType.title)
        }
        .onAppear {
            send(.viewDidAppear)
        }
    }
    
}
