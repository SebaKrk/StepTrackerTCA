//
//  MainFeatureAW+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `MainFeatureAW` state
extension MainFeatureAW {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        ///
        var workoutTypes: [WorkoutOptionAW] = [.planned, .mirroring, .scheduled, .free]
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}
