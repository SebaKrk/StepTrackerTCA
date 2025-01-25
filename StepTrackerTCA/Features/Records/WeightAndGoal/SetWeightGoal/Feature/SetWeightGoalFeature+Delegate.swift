//
//  SetWeightGoalFeature+Delegate.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/01/2025.
//

import ComposableArchitecture
import Foundation

/// Implementation of `SetWeightGoalFeature` delegate
extension SetWeightGoalFeature {
    
    /// A delegate enum to handle events related to `SetWeightGoalFeature`.
    enum Delegate: Equatable {
        
        /// Triggered when the user set weight goal.
        /// - Parameter healthData: An object containing health-related data.
        case setGoal(HealthData)
    }
        
}
