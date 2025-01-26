//
//  CurrentWeightFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `CurrentWeightFeature` state
extension CurrentWeightFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// The data for weight data
        var weightData: [HealthData] = []
        
        /// The most recent health data entry, representing the user's latest recorded weight.
        /// If no data is available, this value will be `nil`.
        var latestWeight: HealthData? = nil
        
        // MARK: - Destination
        
        /// destination from `CurrentWeightFeature`
        @Presents var destination: Destination.State?
        
    }
    
}
