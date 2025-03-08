//
//  StrengthSummaryFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/03/2025.
//


import ComposableArchitecture
import Foundation

/// Defines the actions available in `StrengthSummaryFeature`, handling data fetching,
/// state updates, and user interactions.
extension StrengthSummaryFeature {
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Fetches workout strength data asynchronously.
        case getWorkoutStrengthData
        
        /// Updates the state with new workout strength data.
        ///
        /// - Parameter data: An optional array of `WorkoutStrength` objects representing the fetched data.
        case updateWorkoutStrengthData([WorkoutStrength]?)
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
        }
        
        // MARK: - Destination
        
    }
    
}
