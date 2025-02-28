//
//  SetWeightGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation

/// A protocol defining a service responsible for setting the user's weight goal.
protocol SetWeightGoalService {
    
    /// Sets the user's weight goal.
    ///
    /// - Parameter goal: The target weight goal, encapsulated in a `WeightGoal` object.
    /// - Throws: An error if the operation fails, such as due to validation issues or storage errors.
    ///
    /// This method is asynchronous, allowing for operations such as network requests or database updates.
    func setWeightGoal(_ goal: WeightGoal) async throws
    
}
