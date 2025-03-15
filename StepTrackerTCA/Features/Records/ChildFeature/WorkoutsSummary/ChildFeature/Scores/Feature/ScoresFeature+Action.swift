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
        
        case updateWorkout
        
        // MARK: - View Actions
        
        /// Handles view-related actions.
        case view(View)
        
        /// Defines user interactions within the view.
        enum View {
            
            /// Triggered when the view appears.
            case viewDidAppear
            
            /// Opens the exercise details for a given `MovementType`.
            /// This action is triggered when the user selects a specific movement to inspect.
            ///
            /// - Parameter movement: The selected movement type.
            case openExerciseInfo(any MovementType)
            
            /// Opens the movement details for a given `MovementType` and associated workout sessions.
            /// This action is triggered when the user selects a movement to view more details.
            ///
            /// - Parameters:
            ///   - movement: The selected movement type.
            ///   - sessions: The associated workout sessions.
            case openMovementDetails(any MovementType, [any WorkoutSessionProtocol])
            
            ///
            case goalsButtonTapped
            
        }
        
        // MARK: - Destination
        
        ///
        case openGoalsSheet
        
        /// Destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
