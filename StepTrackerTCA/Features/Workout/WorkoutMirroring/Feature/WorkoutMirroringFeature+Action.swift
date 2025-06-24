//
//  WorkoutMirroringFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `WorkoutMirroringFeature` action
extension WorkoutMirroringFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        ///
        case workoutMetrics(WorkoutMetrics)
        
        ///
        case checkSessionState
        
        ///
        case startMirroringWorkout
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            /// The action when view will disappear to clean up resources
            case viewWillDisappear
            
        }
    }
    
}
