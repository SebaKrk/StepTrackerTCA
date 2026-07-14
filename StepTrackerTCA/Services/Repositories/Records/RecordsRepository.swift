//
//  RecordsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Foundation
import Combine

/// A protocol that defines methods /abstraction for setting and fetching weight goals
protocol RecordsRepository {
    
    /// Fetches the user's weight goal.
    ///
    /// - Returns: The currently set weight goal as a `Double`.
    /// - Throws: An error if the operation fails due to issues such as missing data or database errors.
    func fetchWeightGoal() async throws -> Double?
    
    /// Fetches the user's weight goal along with the date it was set.
    ///
    /// - Returns: An optional `WeightGoal` object containing the weight goal and its associated date.
    ///            Returns `nil` if no goal is found.
    /// - Throws: An error if the operation fails due to database or retrieval issues.
    func fetchWeightGoalWithDate() async throws -> WeightGoal?
    
    /// Sets a new weight goal for the user.
    ///
    /// - Parameter goal: A `WeightGoal` object containing the target weight and its set date.
    /// - Throws: An error if saving the new weight goal fails due to storage issues.
    func setNewWeightGoal(goal: WeightGoal) async throws
    
    ///
    var itemsDidChangePublisher: AnyPublisher<Void, Never> { get set }
}

///// A protocol that defines methods /abstraction for setting and fetching weight goals
//protocol RecordsRepository {
//
//    /// Sets a new weight goal.
//    ///
//    /// This method creates or updates the user's weight goal in the database.
//    ///
//    /// - Parameters:
//    ///   - weight: The new weight goal to be set, represented as a `Double`.
//    ///   - dateAdded: The date when the weight goal was added.
//    /// - Throws: An error if saving the new weight goal fails.
//    func setNewWeightGoal(_ weight: Double, _ dateAdded: Date) throws
//
//    /// Fetches the current weight goal.
//    ///
//    /// This method retrieves the most recently added weight goal from the database.
//    ///
//    /// - Returns: An optional `CurrentWeightEntity` containing the weight goal and its
//    ///   associated metadata. Returns `nil` if no weight goal is found.
//    /// - Throws: An error if fetching the weight goal fails.
//    func fetchWeightGoal() throws -> CurrentWeightEntity?
//
//}
