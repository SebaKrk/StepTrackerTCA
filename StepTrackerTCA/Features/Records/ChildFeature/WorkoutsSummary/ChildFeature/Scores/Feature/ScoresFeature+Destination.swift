//
//  ScoresFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `ScoresFeature` destination
extension ScoresFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `MovementDetailsFeature`
        case showDetails(MovementDetailsFeature)

        /// Represents the destination for displaying in `MovementInfoFeature`.
        case openInfo(MovementInfoFeature)
        
        /// Represents the destination for setting or editing goals.
        //case openGoal(SetEditGoalFeature)
        case openGoal(WorkoutSubmissionFeature)
        
        ///
        //case openSubmitWorkout(SubmitWorkoutFeature)
        case openSubmitWorkout(WorkoutSubmissionFeature)
    }
    
}



