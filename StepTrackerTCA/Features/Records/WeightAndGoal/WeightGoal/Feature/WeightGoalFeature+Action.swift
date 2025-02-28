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
        
        /// Checks whether the user has set a weight goal.
        ///
        /// This action is used to verify if the user has an existing goal before performing other operations.
        case checkWeightGoal
        
        /// Fetches the current weight goal from storage or service.
        ///
        /// This action is dispatched when the feature initializes to retrieve the user’s stored weight goal.
        case fetchWeightGoal
        
        /// Updates the feature’s state with the latest weight goal.
        ///
        /// - Parameter goal: The user's weight goal, encapsulated in a `WeightGoal` object.
        case updateWeightGoal(goal: WeightGoal?)
        
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
