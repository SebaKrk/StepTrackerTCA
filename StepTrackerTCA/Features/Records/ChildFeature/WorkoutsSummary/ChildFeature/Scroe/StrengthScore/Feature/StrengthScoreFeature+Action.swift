//
//  StrengthScoreFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` action
extension StrengthScoreFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        case groupedWorkouts
        case findBestWorkout
        
        // MARK: - View Actions
        
        case view(View)
        
        ///
        enum View {
            
            case viewDidAppear
        }
        
        // MARK: - Destination
        
        case destination(PresentationAction<Destination.Action>)
    }
    
}
