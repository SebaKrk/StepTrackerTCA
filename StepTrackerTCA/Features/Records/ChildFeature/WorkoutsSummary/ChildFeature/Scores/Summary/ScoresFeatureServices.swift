//
//  ScoresFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A protocol defining services related to evaluating workout sessions.
protocol ScoresFeatureServices {
    
    /// Returns the best workout session from the given list of sessions.
    ///
    /// - Parameter sessions: An array of workout sessions conforming to `WorkoutSessionProtocol`.
    /// - Returns: The best workout session or `nil` if no sessions are available.
    func bestSession(from sessions: [any WorkoutSessionProtocol]) -> (any WorkoutSessionProtocol)?
}
