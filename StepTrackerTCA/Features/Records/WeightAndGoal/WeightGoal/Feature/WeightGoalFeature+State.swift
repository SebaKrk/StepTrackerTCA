//
//  WeightGoalFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightGoalFeature` state
extension WeightGoalFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from WeightGoalFeature
        @Presents var destination: Destination.State?
    }
    
}

