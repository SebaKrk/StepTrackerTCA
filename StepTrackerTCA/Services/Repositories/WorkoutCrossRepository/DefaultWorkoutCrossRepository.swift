//
//  DefaultWorkoutCrossRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import CoreData
import Foundation
import Factory

/// The default implementation of the `WorkoutCrossRepository` protocol,
final class DefaultWorkoutCrossRepository: WorkoutCrossRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchWorkoutCrossSummary() async throws -> [WorkoutCross] {
        let fetchRequest = WorkoutCrossEntity.fetchRequest()
        
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { WorkoutCrossMapper.mapEntity(from: $0)}
    }
    
}
