//
//  DefaultWeightGoalServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Factory
import Foundation

final class DefaultWeightGoalServices: WeightGoalService {
    
    // MARK: - Dependencies

    @LazyInjected(\.recordsRepository) private var recordsRepository
    
    // MARK: - API
    
    func fetchWeightGoal() async throws -> CurrentWeightEntity? {
        try? recordsRepository.fetchWeightGoal()
    }
    
}

