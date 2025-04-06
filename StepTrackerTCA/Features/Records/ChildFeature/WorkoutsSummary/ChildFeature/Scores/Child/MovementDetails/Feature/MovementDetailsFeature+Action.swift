//
//  MovementDetailsFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `MovementDetailsFeature` action
extension MovementDetailsFeature {
    
    /// Represents all the actions that can be performed within the `MovementDetailsFeature`.
    @CasePathable
    enum Action: ViewAction {
        
        /// Filters the currently selected movement by exercise name.
        ///
        /// - Triggers: When a specific exercise needs to be displayed, excluding others.
        /// - Updates: `filteredMovement` state to reflect only the selected exercise.
        case filterByMovement
        
        /// Updates the state with a new `GroupedMovement`.
        ///
        /// - Parameter: `GroupedMovement` - The filtered or updated set of movements and goals.
        /// - Updates: `filteredMovement` in the state.
        case update(GroupedMovement)
        
        /// Updates the state with a list of calculated goal intervals.
        ///
        /// - Parameter: `[GoalInterval]` - The list of intervals calculated between workout goals.
        /// - Updates: `state.goalIntervals` with the calculated intervals.
        case updateGoalInterval([GoalInterval])
        
        /// The action responsible for checking and generating goal intervals
        /// based on the user's recorded goals. This action triggers the generation
        /// of `GoalInterval` structures from the provided workout goals in the state.
        ///
        /// - Requires: At least two workout goals to generate valid intervals.
        /// - Updates: `state.goalIntervals` with the calculated intervals.
        case checkGoals(GroupedMovement)
        
        // MARK: - View Actions
        
        /// View-specific actions triggered by UI events.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
    }
    
}
