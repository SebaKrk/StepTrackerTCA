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
        
        ///
        case changePlanerState(WorkoutPlanerState)
        
        ///
        case selectedWorkoutActivityPickerChange(WorkoutActivityType)
        
        ///
        case selectedWorkoutLocationPickerChange(WorkoutLocationType)
        
        ///
        case validate
        
        ///
        case createSingleWorkout
        
        ///
        case updateWorkoutPlan(SingleGoalWorkout)
        
        ///
        case updateWorkoutPreview
        
        ///
        case updateScheduleWorkout
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            ///
            case cancelButtonTapped
            
            ///
            case createWorkoutButtonTapped
            
            ///
            case saveScheduleWorkoutButtonTapped
            
            ///
            case showWorkoutPreview
            
            ///
            case userDidOpenPreview
            
            ///
            case userDidClosePreview
            
        }
    }
    
}
