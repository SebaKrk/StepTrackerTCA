//
//  WorkoutMirroringFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 23/06/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension WorkoutMirroringFeature {
    
    /// Defines all possible actions that can be performed or received by the `WorkoutMirroringFeature`.
    @CasePathable
    enum Action: ViewAction, BindableAction {
        
        // MARK: - Binding Action
        
        /// Action triggered when any of the bindable state properties change.
        case binding(BindingAction<State>)
        
        // MARK: - Core Actions
        
        /// Action containing updated workout metrics data.
        case workoutMetrics(WorkoutMetrics)
        
        /// Action to check the current state of the workout session.
        case checkSessionState
        
        /// Action to initiate the mirroring of the workout data.
        case startMirroringWorkout
        
        // MARK: - View Lifecycle Actions
        
        /// Actions related to SwiftUI view lifecycle and user interactions.
        case view(View)
        
        /// Subset of view-related actions.
        enum View {
            
            /// Triggered when the view has appeared and is ready for initial setup.
            case viewDidAppear
            
            /// Triggered when the view is about to disappear, typically used for cleanup.
            case viewWillDisappear
            
            /// Triggered when the user taps the heart rate zone button.
            case heartRateZoneButtonTapped
            
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
