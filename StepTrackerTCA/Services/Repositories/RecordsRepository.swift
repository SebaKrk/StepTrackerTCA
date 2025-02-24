//
//  RecordsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation

/// A protocol that defines methods /abstraction for setting and fetching weight goals
protocol RecordsRepository {
    
    /// Sets a new weight goal.
    ///
    /// This method creates or updates the user's weight goal in the database.
    ///
    /// - Parameters:
    ///   - weight: The new weight goal to be set, represented as a `Double`.
    ///   - dateAdded: The date when the weight goal was added.
    /// - Throws: An error if saving the new weight goal fails.
    func setNewWeightGoal(_ weight: Double, _ dateAdded: Date) throws
    
    /// Fetches the current weight goal.
    ///
    /// This method retrieves the most recently added weight goal from the database.
    ///
    /// - Returns: An optional `CurrentWeightEntity` containing the weight goal and its
    ///   associated metadata. Returns `nil` if no weight goal is found.
    /// - Throws: An error if fetching the weight goal fails.
    func fetchWeightGoal() throws -> CurrentWeight? //Entity?
    
}
