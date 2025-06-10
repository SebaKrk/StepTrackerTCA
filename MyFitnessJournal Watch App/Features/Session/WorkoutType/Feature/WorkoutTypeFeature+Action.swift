//
//  WorkoutTypeFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/06/2025.
//


import ComposableArchitecture
import HealthKit
import SharedModels

/// Implementation of `WorkoutTypeFeature` action
extension WorkoutTypeFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        // MARK: - Actions
        
        /// Triggers navigation to the training session view with the selected `HKWorkoutActivityType`.
        /// Used internally to update the destination state after a workout type is chosen.
        case show(HKWorkoutActivityType)
        
        // MARK: - View Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Triggered when a workout type is selected in the view.
            /// Sends the selected `WorkoutType` to be handled by the feature.
            case selectedWorkoutType(WorkoutType)
        }
        
        /// Handles navigation and child feature presentation actions.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
