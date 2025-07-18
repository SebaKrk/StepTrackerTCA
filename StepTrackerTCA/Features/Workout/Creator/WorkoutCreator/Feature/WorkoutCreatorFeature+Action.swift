//
//  WorkoutCreatorFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/07/2025.
//

import ComposableArchitecture

/// Implementation of `WorkoutCreatorFeature` action
extension WorkoutCreatorFeature {
    
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Handles changes in bindings for the state.
        case binding(BindingAction<State>)
        
        // MARK: - Actions
        
        case selectedWorkoutActivityPickerChange(WorkoutActivityType)
        
        case selectedWorkoutLocationPickerChange(WorkoutLocationType)
        
        case workoutTitleChanged(String)
        
        case warmupTimeChange(Int?)
        
        case warmupNoteChanged(String)
        
        case coolDownTimeChange(Int?)
        
        case addWodToWods(WorkoutSessionNew)
        
        // MARK: - View actions
        
        /// Used for view actions.
        case view(View)
        
        enum View {
            
            /// The action responsible for completing tasks as soon as the view is displayed.
            case viewDidAppear
            
            case cancelButtonTapped
            
            case workoutTitleSheetTapped
            
            case wodSheetTapped
            
            case workoutTitleSheetDismissed
            
            case openWarmUpSheetPresented
            
            case warmupGoalButtonTapped(SimpleWorkoutGoal)
            
//            case warmupNoteButtonTapped
            
            case openCoolDownSheetPresented
            
            case coolDownButtonTapped(SimpleWorkoutGoal)
            
            case previewButtonTapped
        }
        
        // MARK: - Destination
        
        case destination(PresentationAction<Destination.Action>)
        
    }
    
}
