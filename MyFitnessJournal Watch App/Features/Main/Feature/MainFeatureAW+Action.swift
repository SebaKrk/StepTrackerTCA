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
        
        case view(View)
        
        enum View {
            
            ///
            case viewDidAppear
            
            ///
            case selectedWorkoutOption(WorkoutOptionAW)
        }
        
        // MARK: - Actions
        
        ///
        case openTrainingSheet
        
        // MARK: - Destination
        
        ///
        case show(WorkoutOptionAW)
        
        ///
        case destination(PresentationAction<Destination.Action>)
    }
    
}
