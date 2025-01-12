//
//  ActivityFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ActivityFeature` action
extension ActivityFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        /// Action triggered when the user changes the picker selection.
        ///
        /// - Parameter: `ActivityPeriod` representing the selected period.
        case selectedPickerChange(ActivityPeriod)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Triggered when the user taps on a workout item.
            case tapWorkout(WorkoutData?)
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
        }
        
        // MARK: - Destination
        
        /// Triggered when a workout is selected.
        case workoutSelected(WorkoutData?)
        
        /// Displays detailed information about the selected workout.
        case show(WorkoutData)
        
        /// destination case for navigation
        case destination(PresentationAction<Destination.Action>)
    }
    
}
