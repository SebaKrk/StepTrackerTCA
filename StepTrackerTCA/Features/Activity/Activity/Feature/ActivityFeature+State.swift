//
//  ActivityFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 12/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ActivityFeature` state
extension ActivityFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// A list of all workout data available to display and manage.
        ///
        /// This array holds the raw workout data fetched or provided by the system.
        var workoutData: [WorkoutData] = []
        
        /// The workout currently selected by the user.
        var selectedWorkout: WorkoutData?
        
        /// The currently selected activity period to display on the list.
        /// - Default: `.day`
        var activityPeriod: ActivityPeriod = .day
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
        
    }
    
}
