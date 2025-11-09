//
//  TrainingReadinessFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/09/2025.
//

import ComposableArchitecture
import SharedModels

/// Implementation of `TrainingReadinessFeature` action
extension TrainingReadinessFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Internal actions
        
        case `internal`(Internal)
        
        enum Internal {
            
            ///
            case changeContentState(ContentState)
            
            /// Action triggered after readiness calculation completes
            case readinessCalculated(TrainingReadinessResult)
            
            /// Action triggered when calculation fails
            case calculationFailed(String)
            
            /// Initiates the training readiness data loading process
            case loadReadinessData

            /// Updates the color state based on the current readiness level
            case changeColor
        }
        
        // MARK: - View actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// Action triggered when user pulls to refresh
            case refresh
        }
    }
    
}
