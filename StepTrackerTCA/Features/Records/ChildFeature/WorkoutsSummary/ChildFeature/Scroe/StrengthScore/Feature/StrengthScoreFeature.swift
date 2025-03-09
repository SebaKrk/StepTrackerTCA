//
//  StrengthScoreFeature.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 09/03/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct StrengthScoreFeature {
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                // MARK: - Actions
                
                // MARK: - View Actions
                
                // MARK: - Destination
            case .destination:
                return .none
            }
        }
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` action
extension StrengthScoreFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
        }
        // MARK: - Destination
        
        case destination(PresentationAction<Destination.Action>)
    }
    
}

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` state
extension StrengthScoreFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from `StrengthScoreFeature`
        @Presents var destination: Destination.State?
    }
    
}

/// Implementation of `StrengthScoreFeature` destination
extension StrengthScoreFeature {
    
    @Reducer
    enum Destination {
    }
    
}
