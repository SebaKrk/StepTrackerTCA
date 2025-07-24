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
        
        /// Updates the selected workout activity type
        /// - Parameter activityType: The new workout activity type (e.g., crossTraining, running)
        case selectedWorkoutActivityPickerChange(WorkoutActivityType)
        
        /// Updates the selected workout location type
        /// - Parameter locationType: The new workout location (indoor, outdoor, unknown)
        case selectedWorkoutLocationPickerChange(WorkoutLocationType)
        
        /// Updates the workout title text
        /// - Parameter title: The new workout title string
        case workoutTitleChanged(String)
        
        /// Adds a new WOD (Workout of the Day) to the workout collection
        /// - Parameter workout: The new workout session to add to the list
        case addWodToWods(WorkoutSessionNew)
        
        // MARK: - View actions
        
        /// Used for view actions triggered by user interactions
        case view(View)
        
        enum View {
            /// User tapped the cancel button to dismiss the feature
            case cancelButtonTapped
            
            /// User tapped to show workout title editing sheet
            case workoutTitleSheetTapped
            
            /// User tapped to create a new WOD
            case wodSheetTapped
            
            /// Workout title sheet was dismissed
            case workoutTitleSheetDismissed
            
            /// User tapped to configure warm up session
            case openWarmUpSheetPresented
            
            /// User tapped to configure cool down session
            case openCoolDownSheetPresented
            
            /// User tapped to preview the complete workout
            case previewButtonTapped
            
            case workoutTypeButtonTaped
        }
        
        // MARK: - Destination
        
        /// Handles navigation to different screens (WOD creator, workout preview)
        /// - Parameter action: Navigation action wrapped in PresentationAction
        case destination(PresentationAction<Destination.Action>)
        
        // MARK: - Child Features
        
        /// Handles warm up configuration feature actions
        /// - Parameter action: SessionConfigurationFeature action for warm up phase
        //case warmUpConfiguration(PresentationAction<SessionConfigurationFeature.Action>)
        
        /// Handles cool down configuration feature actions
        /// - Parameter action: SessionConfigurationFeature action for cool down phase
//        case coolDownConfiguration(PresentationAction<SessionConfigurationFeature.Action>)
    }
}
