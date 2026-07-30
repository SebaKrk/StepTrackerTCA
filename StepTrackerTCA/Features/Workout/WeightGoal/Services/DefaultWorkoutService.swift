//
//  DefaultWorkoutService.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/02/2025.
//

import Factory
import Foundation

protocol WeightGoalServiceTest {
    func setWeightGoal(_ weight: Double, date: Date) async throws
    func fetchWeightGoal() async throws -> Double?
}

final class DefaultWeightGoalServiceTest: WeightGoalServiceTest {
    
    // MARK: - Dependencies

    @LazyInjected(\.recordsRepository) private var recordsRepository
    
    // MARK: - API
    
    func setWeightGoal(_ weight: Double, date: Date) async throws {
        let goal = WeightGoal(id:  UUID().uuidString,
                              weight: weight,
                              weightUnit: .kg,
                              dateAdded: date)
        
        try await recordsRepository.setNewWeightGoal(goal: goal)
    }
    
    func fetchWeightGoal() async throws -> Double? {
        try await recordsRepository.fetchWeightGoal()
    }
    
}
