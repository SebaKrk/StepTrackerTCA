//
//  WorkoutCrossRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

protocol WorkoutCrossRepository {
    
    /// Asynchronously fetches WorkoutCross data.
    ///
    /// - Returns: An optional array of `WorkoutCross`
    func fetchWorkoutCrossSummary() async throws -> [WorkoutCross]
    
}
