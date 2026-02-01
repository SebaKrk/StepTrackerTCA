//
//  MetricDetailFeature.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import ComposableArchitecture
import SharedModels
import Foundation

@Reducer
struct MetricDetailFeature {
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            }
        }
    }
    
}

extension MetricDetailFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        case `internal`(Internal)
        
        /// Internal actions for state management and data loading.
        enum Internal { }
        
        case view(View)
        
        /// View-triggered actions.
        enum View { }
    }
    
}

/// Implementation of `MetricDetailFeature` state.
extension MetricDetailFeature {
    
    @ObservableState
    struct State {
        let metricType: MetricTypeDetails
    }
    
}

