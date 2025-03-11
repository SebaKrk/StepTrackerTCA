//
//  StrengthScoreFeature+Destination.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 10/03/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `StrengthScoreFeature` destination
extension StrengthScoreFeature {
    
    @Reducer
    enum Destination {
      
        /// Represents the destination for displaying in `ExerciseInfoFeature`.
        case openInfo(MovementInfoFeature)
    }
    
}
