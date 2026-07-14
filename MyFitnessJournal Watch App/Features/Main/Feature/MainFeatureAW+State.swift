//
//  MainFeatureAW+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/05/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Implementation of `MainFeatureAW` state
extension MainFeatureAW {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The list of workout options available to the user.
        ///
        /// Default values include planned, mirroring, scheduled, and free workouts.
        var workoutOptions: [WorkoutOptionAW] = [.planned, .mirroring, .scheduled, .free]
        
        // MARK: - Destination
        
        /// destination from MovementDetailsFeature
        @Presents var destination: Destination.State?
    }
    
}
