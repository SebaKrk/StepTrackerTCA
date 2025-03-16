//
//  SummaryFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation

/// Defines the actions available in `SummaryFeature`, handling data fetching,
/// state updates, and user interactions.
extension SummaryFeature {
    
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        /// Fetches workout data asynchronously.
        case getData
        
        /// Updates the state with a new `WorkoutSummary`.
        ///
        /// - Parameter summary: The new workout summary data to be stored.
        case updateData(WorkoutSummary)
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Triggered when a navigation button is tapped.
            case navigationButtonTapped(WorkoutType)

        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
