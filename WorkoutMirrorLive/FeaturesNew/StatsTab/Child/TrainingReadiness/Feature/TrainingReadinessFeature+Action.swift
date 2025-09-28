//
//  TrainingReadinessFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/09/2025.
//

import ComposableArchitecture

/// Implementation of `TrainingReadinessFeature` action
extension TrainingReadinessFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Internal actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            /// Akcja wywoływana po obliczeniu readiness
            case readinessCalculated(Int)
        }
        
        // MARK: - View actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
