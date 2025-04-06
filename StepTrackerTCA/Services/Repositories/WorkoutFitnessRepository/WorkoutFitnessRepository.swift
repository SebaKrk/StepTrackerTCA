//
//  WorkoutFitnessRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

protocol WorkoutFitnessRepository {
    
    /// Asynchronously fetches WorkoutFitness data.
    ///
    /// - Returns: An optional array of `WorkoutFitness
    func fetchWorkoutFitnessSummary() async throws -> [WorkoutFitness]
    
}
