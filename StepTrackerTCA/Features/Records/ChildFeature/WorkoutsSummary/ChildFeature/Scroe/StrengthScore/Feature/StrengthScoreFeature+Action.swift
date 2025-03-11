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
        
        /// Represents an action that updates the grouped workouts data.
        case groupedWorkouts
        
        // MARK: - View Actions
        
        /// Represents an action triggered by a view event.
        case view(View)
        
        enum View {
            /// Indicates that the view has appeared.
            case viewDidAppear
            
        }
        
        // MARK: - Destination
        
        /// Represents navigation-related actions within the feature.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
