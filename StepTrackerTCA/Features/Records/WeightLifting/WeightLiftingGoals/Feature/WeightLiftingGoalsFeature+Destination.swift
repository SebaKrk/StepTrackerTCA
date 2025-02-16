//
//  WeightLiftingGoalsFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` destination
extension WeightLiftingGoalsFeature {
    
    @Reducer
    enum Destination {
        
        /// Represents the destination for displaying in `ExerciseInfoFeature`.
        case openInfo(ExerciseInfoFeature)
        
        ///
        case showDetails(ExerciseDetailsFeature)
        
        /// Opens the goal editing feature.
        ///
        /// This destination is used when the user wants to modify an existing weightlifting goal.
        /// It navigates to `SetEditGoalFeature`, where users can update their goal settings.
        case openSetNewGoal(SetEditGoalFeature)
        
    }
    
}

