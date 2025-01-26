//
//  SetWeightGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation

/// A protocol defining a service responsible for setting the user's weight goal.
protocol SetWeightGoalService {
    
    /// Sets the user's weight goal for a specified date.
    ///
    /// - Parameters:
    ///   - weight: The target weight goal to set, represented as a `Double`.
    ///   - date: The date associated with the weight goal.
    /// - Throws: An error if the operation fails, such as due to validation issues or storage errors.
    ///
    /// This method is asynchronous and allows you to perform operations like network requests or database updates.
    func setWeightGoal(_ weight: Double, date: Date) async throws
    
}
