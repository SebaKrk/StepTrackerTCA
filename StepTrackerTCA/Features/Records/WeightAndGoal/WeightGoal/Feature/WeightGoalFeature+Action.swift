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
        
        /// Action triggered to fetch the current weight goal from the storage or service.
        ///
        /// This is typically dispatched to retrieve the user's existing weight goal when the feature is initialized.
        case fetchWeightGoal
        
        /// Maps a fetched weight goal entity to the corresponding state in the feature.
        ///
        /// - Parameter: `CurrentWeightEntity` contains the user's current weight goal and related data.
        case mapToWeightGoal(CurrentWeight) //Entity)
        
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
