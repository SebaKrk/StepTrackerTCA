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
    
    func fetchWeightLiftingStats() async throws -> [WorkoutWeightlifting]? {
        let context = coreDataManger.backgroundContext
        return try await context.perform { () -> [WorkoutWeightlifting]? in
            let fetchRequest: NSFetchRequest<WorkoutWeightliftingEntity> = WorkoutWeightliftingEntity.fetchRequest()
            
            let entities = try context.fetch(fetchRequest)
            guard !entities.isEmpty else { return nil }
            
            return entities.compactMap { entity in
                guard let movement = WeightliftingMovement(rawValue: entity.movement) else {
                    print("Błąd: Nieznana wartość enum \(entity.movement)")
                    return nil
                }
                
                return WorkoutWeightlifting(
                    id: entity.id,
                    movement: movement,
                    date: entity.date,
                    value: entity.value
                )
            }
        }
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
