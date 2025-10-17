//
//  HealthMetricSummaryDetailsCardFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/10/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@Reducer
struct HealthMetricSummaryDetailsCardFeature {
    
    // MARK: - Dependency
    
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

/// Implementation of `HealthMetricSummaryDetailsCardFeature` action
extension HealthMetricSummaryDetailsCardFeature {
    
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

/// Implementation of `HealthMetricSummaryDetailsCardFeature` state
extension HealthMetricSummaryDetailsCardFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        /// The type of health metric being displayed
        let metricType: HealthMetricType
        
        /// Initial data shown while loading fresh data
        let initialData: TrainingComponentScore
    }
    
}

