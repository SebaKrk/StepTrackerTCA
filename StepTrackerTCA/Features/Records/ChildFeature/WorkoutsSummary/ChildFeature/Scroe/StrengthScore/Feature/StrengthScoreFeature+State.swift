//
//  StrengthScoreFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//


import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` state
extension StrengthScoreFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// 
        var data: [WorkoutStrength]
        
        ///
        var groupedWorkoutsData: [GroupedWorkouts]?
        
        // MARK: - Destination
        
        /// destination from `StrengthScoreFeature`
        @Presents var destination: Destination.State?
    }
    
}
