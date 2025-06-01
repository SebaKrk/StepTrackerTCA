//
//  MainFeatureAW+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `MainFeatureAW` action
extension MainFeatureAW {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - View Actions
        
        /// Handles user interactions or lifecycle events from the view layer.
        case view(View)
        
        enum View {
            
            /// Called when the view appears on screen.
            case viewDidAppear
            
            /// Called when a workout option is selected from the UI.
            ///
            /// - Parameter workout: The selected workout option.
            case selectedWorkoutOption(WorkoutOptionAW)
        }
        
        // MARK: - Actions
        
        /// Opens the training summary sheet.
        case openTrainingSheet
        
        // MARK: - Destination
        
        /// Triggers navigation or logic based on the selected workout option.
        ///
        /// - Parameter workout: The selected workout to show.
        case show(WorkoutOptionAW)
        
        /// Handles navigation to a destination view or feature.
        ///
        /// - Parameter action: The destination's scoped action.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
