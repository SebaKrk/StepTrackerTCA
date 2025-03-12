//
//  StrengthScoreFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` action
extension StrengthScoreFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Represents an action that updates the grouped workouts data.
        /// This action is triggered when the workout data needs to be refreshed or reorganized.
        case groupedWorkouts
        
        // MARK: - View Actions
        
        /// Represents an action triggered by a view event.
        /// This action handles interactions originating from the UI.
        case view(View)
        
        /// Defines possible user interactions within the view.
        enum View {
            
            /// Indicates that the view has appeared.
            /// Typically used to trigger data loading or analytics tracking.
            case viewDidAppear
            
            /// Opens the exercise details for a given `MovementType`.
            /// This action is triggered when the user selects a specific movement to inspect.
            ///
            /// - Parameter movement: The selected movement type.
            case openExerciseInfo(any MovementType)
            
            ///
            case navigationButtonTapped(any MovementType)
        }
        
        // MARK: - Destination
        
        /// Represents navigation-related actions within the feature.
        /// Used to manage transitions to other views or modals.
        ///
        /// - Parameter action: The destination-related action.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
