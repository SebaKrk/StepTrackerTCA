//
//  DefaultWeightLiftingRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 15/02/2025.
//

import CoreData
import Foundation
import Factory

/// The default implementation of the `WeightLiftingRepository` protocol,
final class DefaultWeightLiftingRepository: WeightLiftingRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchSessions() async throws -> [any WorkoutSession] {
//        let workouts = try await fetchWeightLiftingStats() ?? []
//        return workouts.map { $0 as any WorkoutSession }
        []
    }
    
    func fetchWeightLiftingStats() async throws -> [WorkoutWeightlifting] {
        let fetchRequest = WorkoutWeightliftingEntity.fetchRequest()
        
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { WorkoutWeightliftingMapper.mapEntity(from: $0)}
        
    }
    
    // MARK: - Mock Data
    /// Asynchronously retrieves dummy weightlifting data for testing or previews.
    ///
    /// - Returns: A tuple containing:
    ///   - `dummyData`: An array of `WeightLiftingMeasurement` objects representing mock measurement data.
    ///   - `goalHistory`: An array of `WeightLiftingGoalHistory` objects representing mock goals.
    ///
    /// This method allows the feature to be tested or previewed without relying on real data sources.
    func getDummyData() async -> (dummyData: [WeightLiftingMeasurement], goalHistory: [WeightLiftingGoalHistory]) {
        await MockWeightLiftingData.getDummyData()
    }
    
}
