//
//  StatsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StatsFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .none
                
            case .view(.settingsButtonTapped):
                state.destination = .settings(SettingsFeature.State())
                return .none
                
                // test
            case .view(.incrementButtonTapped):
                state.counter += 1
                return .none
                
            case .destination(_):
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

/// Implementation of `StatsFeature` action
extension StatsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
                    
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case settingsButtonTapped
            
            //TEST
            /// Action triggered when increment button is tapped
            case incrementButtonTapped

        }
        
        // MARK: - Destination
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}

/// Implementation of `StatsFeature` state
extension StatsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        // TEST
        /// Counter value that will be animated
        var counter: Float = 0

        
        // MARK: - Destination
        
        /// destination from SummaryFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `StatsFeature` destination
extension StatsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `SettingsFeature`.
        case settings(SettingsFeature)
    }
}

