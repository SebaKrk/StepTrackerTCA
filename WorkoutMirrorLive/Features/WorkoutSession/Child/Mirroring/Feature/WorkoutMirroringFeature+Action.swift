//
//  WorkoutMirroringFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/08/2025.
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
        
        // MARK: - Action
        
        ///
        case bottomToolBarStateChanged(WorkoutMirroringToolBarState)
        
        /// Updates the paused state of the workout.
        ///
        /// - Parameter paused: A Boolean indicating whether the workout is paused.
        case pauseChanged(Bool)
        
        ///
        case workoutSessionState(WorkoutSessionStateTest)
        
        /// Updates the current workout metrics with new data.
        ///
        /// - Parameter data: The latest workout metrics from the session.
        case workoutMetrics(WorkoutMetrics)
        
        // MARK: - View Actions
        
        case view(View)
        
        enum View {
            
            /// Action triggered when the view appears on the screen.
            case viewDidAppear
            
            ///
            case bottomToolBarStateTapped(WorkoutMirroringToolBarState)
            
            ///
            case heartRateZoneButtonTapped
            
            ///
            case hideToolBarButtonTapped
            
            /// Called periodically to update the elapsed workout time.
            ///
            /// - Parameter date: The current timestamp used to calculate elapsed time.
            case updateElapsedTime(Date)
            
            // MARK: Camera
            ///
            case cameraButtonTapped
            
            ///
            case recordButtonTapped
            
            // MARK: Music
            
            ////
            case playPauseMusicButtonTapped
            
            ///
            case forwardMusicButtonTapped
            
            ///
            case backwardMusicButtonTapped
            
            // MARK: Workout
            
            ///
            case pauseWorkoutButtonTaped(Bool)
            
            ///
            case endWorkoutButtonTapped
            
            ///
            case resumeWorkoutButtonTapped(Bool)
            
            ////
            case xMarkButtonTapped
        }
        
        // MARK: - Navigation and Presentation
        
        /// Action to handle navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)
    }
}
