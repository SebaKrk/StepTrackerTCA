//
//  DefaultRecordsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 26/01/2025.
//

import Factory
import Foundation
import CoreData
import Combine

final class DefaultRecordsRepository: RecordsRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Publishers
    
    public var itemsDidChangePublisher: AnyPublisher<Void, Never>
    private let itemsDidChangeSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - Lifecycle
    
    public init() {
        itemsDidChangePublisher = itemsDidChangeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - API
    
    func setNewWeightGoal(goal: WeightGoal) async throws {
        let context = backgroundContext
        try await context.perform {
            let request: NSFetchRequest<GoalWeightEntity> = GoalWeightEntity.fetchRequest()
            request.fetchLimit = 1
            
            if let existingWeightGoal = try context.fetch(request).first {
                existingWeightGoal.weight = goal.weight
                existingWeightGoal.weightUnit = goal.weightUnit.rawValue
                existingWeightGoal.dateAdded = goal.dateAdded
                
            } else {
                let newWeightGoal = GoalWeightEntity(context: context)
                newWeightGoal.id = goal.id
                newWeightGoal.weight = goal.weight
                newWeightGoal.weightUnit = goal.weightUnit.rawValue
                newWeightGoal.dateAdded = goal.dateAdded
            }
            
            try self.saveData(context: context)
        }
    }
    
    func fetchWeightGoal() async throws -> Double {
        let context = coreDataManger.backgroundContext
        return try await context.perform {
            let fetchRequest: NSFetchRequest<GoalWeightEntity> = GoalWeightEntity.fetchRequest()
            fetchRequest.fetchLimit = 1
            return try context.fetch(fetchRequest).first?.weight ?? 0
        }
    }
    
    func fetchWeightGoalWithDate() async throws -> WeightGoal? {
        let context = coreDataManger.backgroundContext
        return try await context.perform { () -> WeightGoal? in
            let fetchRequest: NSFetchRequest<GoalWeightEntity> = GoalWeightEntity.fetchRequest()
            fetchRequest.fetchLimit = 1
            guard let result = try context.fetch(fetchRequest).first else { return nil }

            
            let weightUnit = WeightUnit(rawValue: result.weightUnit) ?? .kg
            
            return WeightGoal(id: result.id,
                              weight: result.weight,
                              weightUnit: weightUnit,
                              dateAdded: result.dateAdded)
        }
    }
    
    // MARK: - Core Data Helpers
    
    private func saveData(context: NSManagedObjectContext) throws {
        print("✅ Core Data zapisane, wysyłam event")
        try context.save()
        itemsDidChangeSubject.send()
    }
    
}


//import Factory
//import Foundation
//import SwiftData

//final class DefaultRecordsRepository: RecordsRepository {
//    
//    // MARK: - Dependencies
//    
//    @LazyInjected(\.swiftDataManager) private var swiftDataManager
//    
//    lazy var context = swiftDataManager.mainContext
//    
//    // MARK: - API
//    
//    func setNewWeightGoal(_ weight: Double, _ dateAdded: Date) throws {
//        if let existingWeightGoal = try fetchWeightGoal() {
//            existingWeightGoal.weight = weight
//            existingWeightGoal.dateAdded = dateAdded
//        } else {
//            let newWeightGoal = CurrentWeightEntity(id: UUID().uuidString, weight: weight, dateAdded: dateAdded)
//            context.insert(newWeightGoal)
//        }
//        try context.save()
//    }
//    
//    func fetchWeightGoal() throws -> CurrentWeightEntity? {
//        var descriptor = FetchDescriptor<CurrentWeightEntity>()
//        descriptor.fetchLimit = 1
//        return try context.fetch(descriptor).first
//        return nil
//    }
//    
//}
