//
//  TrainingSessionTabFeature+Action.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

/// Implementation of `TrainingSessionTabFeature` action
extension TrainingSessionTabFeature {
    
    @CasePathable
    enum Action: ViewAction {
        
        /// Action triggered when the user changes the selected tab.
        case tabChanged(WorkoutSessionScreenAW)
        
        /// Sets the selected workout activity type and triggers workout start.
        case setWorkoutActivityType(HKWorkoutActivityType)
        
        /// Updates the state to reflect whether the workout session is running.
        ///
        /// - Parameter isRunning: Boolean indicating the running state.
        case workoutSessionIsRunningChanged(Bool)
        
        /// Cancels active effects such as metrics or session monitoring streams.
        case cancelEffect
        
        /// Starts the workout session, including monitoring streams for session status and metrics.
        case workoutStart
        
        
        case prepareWorkout
        
        case showCountDown
        
        // MARK: - Actions
        
        case view(View)
        
        /// Sub-actions for view-related events.
        enum View {
            
            /// Triggered when the view appears, used to initialize workout setup.
            case viewDidAppear
            
            /// User-triggered tab change to the workout screen.
            case changeTab
        }
        
        // MARK: - Child Actions
        
        /// Delegate action for training controls.
        case controls(TrainingControlsFeature.Action)
        
        /// Delegate action for workout metrics.
        case metric(TrainingMetricFeature.Action)
        
        // MARK: - Destination
        
        /// Handles navigation and child feature presentation actions.
        case destination(PresentationAction<Destination.Action>)
    }
    
}
