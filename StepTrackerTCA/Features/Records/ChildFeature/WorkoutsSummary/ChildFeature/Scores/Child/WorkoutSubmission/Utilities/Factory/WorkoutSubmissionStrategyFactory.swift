//
//  WorkoutSubmissionStrategyFactory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import Foundation

/// Factory protocol for creating appropriate workout submission strategies.
protocol WorkoutSubmissionStrategyFactory {
    /// Returns a strategy instance based on the submission type.
    ///
    /// - Parameter service: The type of submission operation.
    /// - Returns: An appropriate strategy conforming to `WorkoutSubmissionStrategy`.
    func strategy(for service: SubmissionType) -> WorkoutSubmissionStrategy
}
