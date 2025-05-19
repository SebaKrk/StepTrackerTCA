//
//  WorkoutPlanerFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import ComposableArchitecture
import Foundation
import WorkoutKit

/// Implementation of `WorkoutPlanerFeature` action
extension WorkoutPlanerFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Changes the state of the workout planner screen.
        case changePlanerState(WorkoutPlanerState)
        
        /// Called when the user selects a workout activity type.
        case selectedWorkoutActivityPickerChange(WorkoutActivityType)
        
        /// Called when the user selects a workout location type.
        case selectedWorkoutLocationPickerChange(WorkoutLocationType)
        
        /// Triggers validation of the current input or workout plan.
        case validate
        
        /// Starts the creation of a single workout.
        case createSingleWorkout
        
        /// Updates the current workout plan with the provided workout.
        case updateWorkoutPlan(SingleGoalWorkout?)
        
        /// Toggles the workout preview state.
        case updateWorkoutPreview
        
        /// Updates the scheduled workout details.
        case updateScheduleWorkout
        
        // MARK: - View actions
        
        /// Actions triggered by user interactions in the view.
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            case viewDidAppear
            
            /// Triggered when the cancel button is tapped.
            case cancelButtonTapped
            
            /// Triggered when the create workout button is tapped.
            case createWorkoutButtonTapped
            
            /// Triggered when the save scheduled workout button is tapped.
            case saveScheduleWorkoutButtonTapped
            
            /// Triggered to show the workout preview.
            case showWorkoutPreview
            
            /// Triggered when the user opens the workout preview.
            case userDidOpenPreview
            
            /// Triggered when the user closes the workout preview.
            case userDidClosePreview
            
        }
    }
}

