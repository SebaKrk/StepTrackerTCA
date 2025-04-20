//
//  DefaultWorkoutFitnessRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import CoreData
import Foundation
import Factory

/// The default implementation of the `WorkoutFitnessRepository` protocol,
final class DefaultWorkoutFitnessRepository: WorkoutFitnessRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchWorkoutFitnessSummary() async throws -> [WorkoutFitness] {
        let fetchRequest = WorkoutFitnessEntity.fetchRequest()
        
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { WorkoutFitnessMapper.mapEntity(from: $0)}
    }
    
}
