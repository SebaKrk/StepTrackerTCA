//
//  WeightLiftingGoalHistory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Foundation

/// A model representing the historical record of weightlifting goals.
///
/// This structure stores a history of weightlifting goals for a specific movement,
/// allowing tracking of past goals and identifying the most recent goal.
struct WeightLiftingGoalHistory: Identifiable, Codable {
    
    /// A unique identifier for the goal history entry.
    let id: String
    
    /// A list of weightlifting goals associated with this history entry.
    var goals: [WeightLiftingGoal]

    /// The most recent goal in the history.
    ///
    /// This computed property returns the last goal in the `goals` array, assuming
    /// the latest goal is always appended at the end.
    var currentGoal: WeightLiftingGoal? {
        return goals.last
    }
}
