//
//  WeightLiftingStatsFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `WeightLiftingStatsFeature` state
extension WeightLiftingStatsFeature {
    @ObservableState
    struct State {
        // MARK: - Properties
        
        // MARK: - Destination
        
        /// destination from `WeightLiftingStatsFeature`
        @Presents var destination: Destination.State?
    }
    
}
