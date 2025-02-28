//
//  DefaultSetWeightGoalService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Factory
import Foundation

final class DefaultSetWeightGoalService: SetWeightGoalService {
    
    // MARK: - Dependencies

    @LazyInjected(\.recordsRepository) private var recordsRepository
    
    // MARK: - API
    
    func setWeightGoal(_ goal: WeightGoal) async throws {
        try await recordsRepository.setNewWeightGoal(goal: goal)
    }
    
}
