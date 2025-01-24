//
//  PersonDataFeature+State.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 23/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `PersonDataFeature` state
extension PersonDataFeature {
    
    @ObservableState
    struct State {
        // MARK: - Properties
        
        /// The data for weight data
        var weightData: [HealthData] = []
        
        // MARK: - Destination
        
        /// destination from ActivityFeature
        @Presents var destination: Destination.State?
        
        // MARK: - Child actions
        
        /// Stores the information contained in the `CurrentWeightFeature`
        var currentWeight = CurrentWeightFeature.State()
        
        /// Stores the information contained in the `WeightGoalFeature
        var weightGoal = WeightGoalFeature.State()
    }
}

