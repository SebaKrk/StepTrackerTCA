//
//  WeightGoalFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalFeature` action
extension WeightGoalFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// test
            case navigationButtonTapped
        }
        // MARK: - Destination
        
        ///
        case show
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
