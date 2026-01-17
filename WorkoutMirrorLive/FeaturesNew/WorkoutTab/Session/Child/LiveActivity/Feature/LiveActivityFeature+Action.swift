//
//  LiveActivityFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/01/2026.
//
    
import ComposableArchitecture
import SharedModels

/// Implementation of `LiveActivityFeature` action
extension LiveActivityFeature {
    
    enum Action: Equatable {
        
        
        /// Called when workout activity starts successfully
        case workoutActivityStarted(activityID: String)
        
        /// Called when workout activity stops successfully
        case workoutActivityStopped
        
        // MARK: Workout Actions
        
        /// Start a new workout Live Activity
        case startWorkout(
            workoutName: String,
            initialState: WorkoutSessionActivityAttributes.ContentState
        )
        
        /// Update existing workout Live Activity
        case updateWorkout(WorkoutSessionActivityAttributes.ContentState)
        
        /// Stop workout Live Activity
        case stopWorkout
        
    }
    
}
