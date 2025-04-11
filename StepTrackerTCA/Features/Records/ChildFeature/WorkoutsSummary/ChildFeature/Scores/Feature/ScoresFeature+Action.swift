//
//  ScoresFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation

/// Defines the actions available in `ScoresFeature`, handling data fetching,
/// state updates, and user interactions.
extension ScoresFeature {
    @CasePathable
    enum Action: ViewAction {
        // MARK: - Actions
        
        /// Fetches workout data for a specific workout type.
        /// - Parameter workoutType: The type of workout to fetch data for.
        case getData(for: WorkoutType)
        
        /// Filters the provided summary into specific movements.
        /// - Parameter summary: The summary data to be filtered.
        case filteredMovements(Summary)
        
        /// Maps the summary data to grouped movements.
        /// - Parameter summary: The summary data to be grouped.
        case mapToGroupedMovement(Summary)
        
        /// Updates the state with the provided summary data.
        /// - Parameter summary: The `Summary` object containing the updated workout data.
        case updateData(Summary)
        
        /// Updates the state with a newly grouped movement.
        /// - Parameter groupedMovement: The grouped movement to be updated.
        case updateGroupedMovement(GroupedMovement)
        
        /// Updates the filtered data with a list of filtered movements.
        /// - Parameter filteredMovements: The array of `FilteredMovement` objects.
        case updateFilteredData([FilteredMovement])

        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Opens exercise information for a specific exercise.
            /// - Parameter movement: The name of the movement to display information for.
            case openExerciseInfo(String)
            
            /// Opens the movement details screen for a specific movement.
            /// - Parameter movement: The name of the movement to display details for.
            case openMovementDetails(String)
            
            /// Triggered when the user taps the goals button.
            /// Opens the goal setting sheet for defining or updating a movement goal.
            case goalsButtonTapped
            
            ///
            case submitWorkoutScoreButtonTapped
            
        }
        
        // MARK: - Destination
        
        /// Opens a sheet responsible for setting or editing a goal for a specific exercise.
        ///
        /// This action is triggered when the user wants to define or modify their goal
        /// for a selected movement type.
        case openGoalsSheet
        
        ///
        case openSubmitWorkoutSheet
        
        /// Destination case for handling navigation actions.
        /// - Parameter action: The action to be performed within the destination.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
