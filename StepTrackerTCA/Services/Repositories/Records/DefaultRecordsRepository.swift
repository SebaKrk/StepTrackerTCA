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
    
    func setNewWeightGoal2(goal: WeightGoal) async throws {
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
    
    func setNewWeightGoal(goal: WeightGoal) async throws {
        let context = backgroundContext
        try await context.perform {
            // Pobierz istniejącego użytkownika lub utwórz nowego
            let userRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            userRequest.fetchLimit = 1
            
            let user: UserEntity
            if let existingUser = try context.fetch(userRequest).first {
                user = existingUser
            } else {
                user = UserEntity(context: context)
                user.id = UUID().uuidString
                user.email = "seba.s@example.com" 
                user.healthKitEnabled = true // Domyślna wartość
            }
            
            // Pobierz lub utwórz encję GoalsEntity
            let goals: GoalsEntity
            if let existingGoals = user.goals {
                goals = existingGoals
            } else {
                goals = GoalsEntity(context: context)
                goals.id = UUID().uuidString
                goals.user = user
            }

            // Pobierz istniejący GoalWeightEntity dla użytkownika
            let weightGoalRequest: NSFetchRequest<GoalWeightEntity> = GoalWeightEntity.fetchRequest()
            weightGoalRequest.predicate = NSPredicate(format: "goals.user.id == %@", user.id)
            weightGoalRequest.fetchLimit = 1
            
            if let existingWeightGoal = try context.fetch(weightGoalRequest).first {
                // Aktualizuj istniejący cel
                existingWeightGoal.weight = goal.weight
                existingWeightGoal.weightUnit = goal.weightUnit.rawValue
                existingWeightGoal.dateAdded = goal.dateAdded
            } else {
                // Utwórz nowy cel wagowy i przypisz do GoalsEntity
                let newWeightGoal = GoalWeightEntity(context: context)
                newWeightGoal.id = goal.id
                newWeightGoal.weight = goal.weight
                newWeightGoal.weightUnit = goal.weightUnit.rawValue
                newWeightGoal.dateAdded = goal.dateAdded
                newWeightGoal.goals = goals
                goals.goalWeight = newWeightGoal
            }

            // Zapisz zmiany w tle
            try self.saveData(context: context)
        }
    }
    
    func fetchWeightGoal() async throws -> Double? {
        let context = coreDataManger.backgroundContext
        return try await context.perform {
            let fetchRequest: NSFetchRequest<GoalWeightEntity> = GoalWeightEntity.fetchRequest()
            fetchRequest.fetchLimit = 1
            return try context.fetch(fetchRequest).first?.weight
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
