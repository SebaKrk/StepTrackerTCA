//
//  DefaultWeightLiftingStatsServices.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 08/02/2025.
//

import Factory
import Foundation

final class DefaultWeightLiftingStatsServices: WeightLiftingStatsServices {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.weightLiftingRepository) private var repository
    
    // MARK: - API
    
    /// Maps the provided goal history and measurements to an array of display models.
    func mapData(history: [WeightLiftingGoalHistory], measurements: [WeightLiftingMeasurement]) -> [WeightLiftingDisplayModel] {
        let allGoals = history.flatMap { $0.goals }
        let sortedGoals = allGoals.sorted { $0.createdDate > $1.createdDate }
        var latestGoals: [WeightLiftingGoal] = []
        for goal in sortedGoals {
            if !latestGoals.contains(where: { $0.movement == goal.movement }) {
                latestGoals.append(goal)
            }
        }
        
        return latestGoals.map { goal in
            let latestResult = measurements
                .filter { $0.name == goal.movement }
                .sorted { $0.date > $1.date }
                .first?.value ?? 0
            return WeightLiftingDisplayModel(
                id: goal.id,
                movement: goal.movement,
                goal: goal.target,
                latestResult: latestResult
            )
        }
    }
    
    // MARK: - Mock
    
    /// Asynchronously retrieves dummy weightlifting data for testing or preview purposes.
    func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory]) {
        await repository.getDummyData()
    }
    
}
