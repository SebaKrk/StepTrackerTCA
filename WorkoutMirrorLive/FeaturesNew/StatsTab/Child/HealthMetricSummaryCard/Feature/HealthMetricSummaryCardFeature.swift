//
//  HealthMetricSummaryCardFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 11/10/2025.
//

import ComposableArchitecture
import Foundation

@Reducer
struct HealthMetricSummaryCardFeature {
    
    // MARK: - Dependency
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}

/// Implementation of `HealthMetricSummaryCardFeature` action
extension HealthMetricSummaryCardFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        case internalAction(Internal)
        
        enum Internal {

        }
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
        }
        

    }
}

/// Implementation of `HealthMetricSummaryCardFeature` state
extension HealthMetricSummaryCardFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
    }
    
}

