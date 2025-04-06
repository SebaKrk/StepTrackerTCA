//
//  WorkoutHeroWodRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

protocol WorkoutHeroWodRepository {
    
    /// Asynchronously fetches WorkoutCross data.
    ///
    /// - Returns: An optional array of `WorkoutHeroWod`
    func fetchWorkoutHeroWodSummary() async throws -> [WorkoutHeroWod]
    
}
