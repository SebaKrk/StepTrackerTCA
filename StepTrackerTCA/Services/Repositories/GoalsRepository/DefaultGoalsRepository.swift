//
//  DefaultGoalsRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/03/2025.
//

import CoreData
import Factory
import Foundation

final class DefaultGoalsRepository: GoalsRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func fetchAllGoals() async throws -> [WorkoutGoal] {
        let fetchRequest = GoalWorkoutEntity.fetchRequest()
        return try coreDataManger.backgroundContext
            .fetch(fetchRequest)
            .map { goal in
                WorkoutGoal(
                    id: goal.id,
                    workoutType: goal.workoutType,
                    movement: goal.movement,
                    date: goal.date,
                    value: goal.value
                )
            }
    }
    
    func setNewGoal(for workoutType: WorkoutType,
                    _ movement: String,
                    date: Date,
                    value: String,
                    unit: String
    ) async throws {
        let context = backgroundContext
        
        try await context.perform {
            do {
                // TODO: - Usunąć tworzenie/sprawdzanie user - logowanie usera
                let user = try self.fetchUser(in: context)
                
                // TODO: - Przy tworzeniu/logowaniu User ma powstać z GoalsEntity
                let goals = self.fetchOrCreateGoals(for: user, in: context)
                
                let newGoal = self.createGoalEntity(
                    workoutType: workoutType,
                    movement: movement,
                    date: date,
                    value: value,
                    unit: unit,
                    in: context
                )
                
                self.addGoal(newGoal, to: goals)
                
                try self.saveData(context: context)
            } catch {
                
                // TODO: - Obsługa błędów, zbiorczy Enum dla wszystkich repo
                print("❌ Error in setNewGoal: \(error)")
                throw error
            }
        }
    }
    
    
    // MARK: - Methods
    
    private func fetchUser(in context: NSManagedObjectContext) throws -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        guard let user = try context.fetch(fetchRequest).first else {
            throw NSError(domain: "WorkoutError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ No user found in database."])
        }
        return user
    }
    
    /// Fetching or Creating GoalsEntity
    private func fetchOrCreateGoals(for user: UserEntity, in context: NSManagedObjectContext) -> GoalsEntity {
        if let existingGoals = user.goals {
            return existingGoals
        } else {
            let newGoals = GoalsEntity(context: context)
            user.goals = newGoals
            return newGoals
        }
    }
    
    /// creating GoalWorkoutEntity
    private func createGoalEntity(workoutType: WorkoutType, movement: String, date: Date, value: String, unit: String, in context: NSManagedObjectContext) -> GoalWorkoutEntity {
        let goal = GoalWorkoutEntity(context: context)
        goal.id = UUID().uuidString
        goal.workoutType = workoutType.rawValue
        goal.movement = movement
        goal.date = date
        goal.value = Double(value) ?? 0.0
        return goal
    }
    
    ///Adding Goal to GoalsEntity
    private func addGoal(_ goal: GoalWorkoutEntity, to goals: GoalsEntity) {
        if goals.goalsWorkout == nil {
            goals.goalsWorkout = []
        }
        
        goals.goalsWorkout?.insert(goal)
    }
    
    
    private func fetchGoals(for userId: String, in context: NSManagedObjectContext) throws -> GoalsEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
        fetchRequest.fetchLimit = 1
        
        guard let user = try context.fetch(fetchRequest).first else {
            throw NSError(domain: "WorkoutError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ No user found in database."])
        }
        
        guard let goals = user.goals else {
            throw NSError(domain: "WorkoutError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ No goals found for user."])
        }
        
        return goals
    }
    
    // MARK: - Core Data Helpers
    
    private func saveData(context: NSManagedObjectContext) throws {
        do {
            try context.save()
            print("💾 Changes saved in Core Data")
        } catch {
            print("❌ Błąd przy zapisywaniu danych: \(error)")
            throw error
        }
    }
    
}
