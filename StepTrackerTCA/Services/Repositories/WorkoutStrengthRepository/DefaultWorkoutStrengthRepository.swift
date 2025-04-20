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
    
    func fetchWorkoutStrengthSummary() async throws -> [WorkoutStrength] {
        let fetchRequest = WorkoutStrengthEntity.fetchRequest()
        
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { WorkoutStrengthMapper.mapEntity(from: $0)}
    }
    
}

