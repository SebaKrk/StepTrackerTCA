//
//  DefaultRecordsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Factory
import Foundation
import SwiftData

final class DefaultRecordsRepository: RecordsRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.swiftDataManager) private var swiftDataManager
    
    lazy var context = swiftDataManager.mainContext
    
    // MARK: - API
    
    func setNewWeightGoal(_ weight: Double, _ dateAdded: Date) throws {
        if let existingWeightGoal = try fetchWeightGoal() {
            existingWeightGoal.weight = weight
            existingWeightGoal.dateAdded = dateAdded
        } else {
            let newWeightGoal = CurrentWeightEntity(id: UUID().uuidString, weight: weight, dateAdded: dateAdded)
            context.insert(newWeightGoal)
        }
        try context.save()
    }
    
    func fetchWeightGoal() throws -> CurrentWeightEntity? {
        var descriptor = FetchDescriptor<CurrentWeightEntity>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
}
