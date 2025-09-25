//
//  StatsFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 20/08/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub

@Reducer
struct StatsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var authorizationManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Action
                
                // MARK: - View Action
            case .view(.viewDidAppear):
                return .run { send in
                    let result = await self.authorizationManager.requestAuthorization()
                    switch result {
                    case .success:
                        print("success")
                        
                    case .failure(let error):
                        print("Authorization failed with error: \(error.localizedDescription)")
                    }
                }
                
            case .view(.personButtonTapped):
                state.destination = .personSettings(PersonSettingsFeature.State())
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
            case personButtonTapped

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
        
        // MARK: - Destination
        
        /// destination from SummaryFeature
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `StatsFeature` destination
extension StatsFeature {
    
    @Reducer
    enum Destination {
        case personSettings(PersonSettingsFeature)
    }
}

