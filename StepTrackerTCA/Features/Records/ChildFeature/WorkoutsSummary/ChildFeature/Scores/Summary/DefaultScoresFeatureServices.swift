//
//  DefaultScoresFeatureServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/03/2025.
//

import Foundation

/// A default implementation of `ScoresFeatureServices` that provides functionality for evaluating workout sessions.
final class DefaultScoresFeatureServices: ScoresFeatureServices {
    
    // MARK: - API
    
    /// Returns the best workout session from the given list of sessions.
    func bestSession(from sessions: [any WorkoutSessionProtocol]) -> (any WorkoutSessionProtocol)? {
        return sessions.max { Double($0.value) ?? 0 < Double($1.value) ?? 0 }
    }
    
}
