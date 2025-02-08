//
//  WeightLiftingGoalsFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingGoalsFeature` state
extension WeightLiftingGoalsFeature {
    @ObservableState
    struct State {
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from `WeightLiftingGoalsFeature`
        @Presents var destination: Destination.State?
    }
    
}
