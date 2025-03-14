//
//  DefaultWorkoutStrengthRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 07/03/2025.
//

import CoreData
import Foundation
import Factory

/// The default implementation of the `WorkoutStrengthRepository` protocol,
final class DefaultWorkoutStrengthRepository: WorkoutStrengthRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchSessions() async throws -> [any WorkoutSessionProtocol] {
        let workouts = try await fetchWorkoutStrengthSummary() ?? []
        return workouts.map { $0 as any WorkoutSessionProtocol }
    }
    
    func fetchWorkoutStrengthSummary() async throws -> [WorkoutStrength]? {
        let context = coreDataManger.backgroundContext
        return try await context.perform { () -> [WorkoutStrength]? in
            let fetchRequest: NSFetchRequest<WorkoutStrengthEntity> = WorkoutStrengthEntity.fetchRequest()
            
            let entities = try context.fetch(fetchRequest)
            guard !entities.isEmpty else { return nil }
            
            return entities.compactMap { entity in
                guard let movement = StrengthMovement(rawValue: entity.movement) else {
                    print("Błąd: Nieznana wartość enum \(entity.movement)")
                    return nil
                }
                
                return WorkoutStrength(
                    id: entity.id,
                    movement: movement,
                    date: entity.date,
                    value: entity.value
                )
            }
        }
    }
    
}

