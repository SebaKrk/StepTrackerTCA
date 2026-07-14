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
        
        /// Fetches workout data.
        case getData
        
        /// Updates the state with the provided summary data.
        /// - Parameter summary: The `Summary` object containing the updated workout data.
        case updateData(Summary)
        
        /// Groups the provided summary data for display or further processing.
        /// - Parameter summary: The `Summary` object containing raw workout data to be grouped.
        case groupedData(Summary)
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Triggered when a navigation button is tapped.
            case navigationButtonTapped(WorkoutType)
            
            /// Triggered when the "+" button is tapped when user don't have any data..
            /// Propagates an action upward to the parent feature, which opens a sheet.
            case addMetricButtonPressed
            
        }
        
        // MARK: - Destination
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
