//
//  DefaultWorkoutHeroWodRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import CoreData
import Foundation
import Factory

/// The default implementation of the `DefaultWorkoutHeroWodRepository` protocol,
final class DefaultWorkoutHeroWodRepository: WorkoutHeroWodRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchWorkoutHeroWodSummary() async throws -> [WorkoutHeroWod] {
        let fetchRequest = WorkoutHeroEntity.fetchRequest()
        
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { WorkoutHeroWodMapper.mapEntity(from: $0)}
    }
    
}

