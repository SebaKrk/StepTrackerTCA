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
        /// The user's weight goal represented by `HealthData`. It is optional.
        ///
        /// Example: `weightGoal = .init(date: .now, value: 95)`
        var weightGoal: HealthData?
        
        // MARK: - Destination
        
        /// destination from WeightGoalFeature
        @Presents var destination: Destination.State?
    }
    
}
