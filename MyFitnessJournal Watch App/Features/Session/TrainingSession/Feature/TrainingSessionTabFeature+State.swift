//
//  TrainingSessionTabFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/06/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

/// Implementation of `TrainingSessionTabFeature` state
extension TrainingSessionTabFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The currently selected workout activity type, e.g., running, cycling.
        var selectedWorkout: HKWorkoutActivityType?
        
        /// Indicates whether the workout session is currently running.
        var workoutSessionIsRunning: Bool = false
        
        /// The currently selected tab in the workout session interface.
        var selectedTab: WorkoutSessionScreenAW = .workout
        
        /// The elapsed workout time used for tracking duration.
        var elapsedTime: TimeInterval = 0
        
        var showCountDownView: Bool = false
        
        // MARK: - Child State
        
        /// State for managing the training control buttons and pause/resume status.
        var controls: TrainingControlsFeature.State {
            get {
                .init(sessionIsRunning: workoutSessionIsRunning)
            }
            set {
                workoutSessionIsRunning = newValue.sessionIsRunning
            }
        }
        
        /// State for displaying and managing real-time workout metrics.
        var metric = TrainingMetricFeature.State()
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}
