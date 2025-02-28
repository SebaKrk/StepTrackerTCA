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
        
        /// The user's current weight goal.
        ///
        /// This property stores the user's weight goal as an optional `WeightGoal` object.
        /// If `nil`, it indicates that no weight goal has been set.
        ///
        /// Example usage:
        /// ```swift
        /// state.weightGoal = WeightGoal(date: .now, value: 95)
        /// ```
        var weightGoal: WeightGoal? = nil
        
        // MARK: - Destination
        
        /// Represents the navigation state for `WeightGoalFeature`, determining the active destination.
        @Presents var destination: Destination.State?
    }
    
}
