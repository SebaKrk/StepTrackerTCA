//
//  DefaultWorkoutSubmissionStrategyFactory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 13/04/2025.
//

import Foundation

/// Default implementation of the strategy factory.
struct DefaultWorkoutSubmissionStrategyFactory: WorkoutSubmissionStrategyFactory {
    /// Creates a submission strategy instance based on the selected submission type.
    ///
    /// - Parameter type: The selected submission type.
    /// - Returns: A concrete strategy instance.
    func strategy(for type: SubmissionType) -> WorkoutSubmissionStrategy {
        switch type {
        case .setGoal:
            return SetGoalStrategy(service: DefaultSetEditGoalService())
        case .submit:
            return SubmitWorkoutStrategy(service: DefaultSubmitWorkoutService())
        }
    }
}
