//
//  WorkoutMirroringFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/08/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `WorkoutMirroringFeature` state
extension WorkoutMirroringFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        var elapsedTime: TimeInterval = 0
        var pausedElapsedTime: TimeInterval = 0
        var isPaused: Bool = false
        
        ///
        var mirroringToolBarState: WorkoutMirroringToolBarState = .none
        
        ///
        var isActiveCamera: Bool = false
        
        ///
        var recordIsActive: Bool = false
        
        ///
        var isToolbarHidden: Bool = false
        
        ///
        var workoutSessionState: WorkoutSessionStateTest = .running
        
        // MARK: - Destination
        
        /// destination from WorkoutCreatorFeature
        @Presents var destination: Destination.State?
        
    }
    
}
