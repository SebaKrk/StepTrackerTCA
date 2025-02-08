//
//  WeightLiftingStatsFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingStatsFeature` action
extension WeightLiftingStatsFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// Triggered when a navigation button is tapped.
            case navigationButtonTapped
        }
        
        // MARK: - Destination
        
        /// Triggered to display a destination or handle navigation actions.
        case show
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
