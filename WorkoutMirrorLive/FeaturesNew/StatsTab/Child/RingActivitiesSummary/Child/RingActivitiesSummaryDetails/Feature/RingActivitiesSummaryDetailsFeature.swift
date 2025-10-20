//
//  RingActivitiesSummaryDetailsFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 19/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

@Reducer
struct RingActivitiesSummaryDetailsFeature {
    
    // MARK: - Dependency
    
    @Dependency(\.activityRingManager) var activityRingManager
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Internal Action
                
                // MARK: - View Action
                
            case .view(.viewDidAppear):
                return .none
            }
        }
    }
    
}

/// Implementation of `RingActivitiesSummaryDetailsFeature` action
extension RingActivitiesSummaryDetailsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal Actions
        
        case `internal`(Internal)
        
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

/// Implementation of `RingActivitiesSummaryDetailsFeature` state
extension RingActivitiesSummaryDetailsFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
  
    }
    
}
