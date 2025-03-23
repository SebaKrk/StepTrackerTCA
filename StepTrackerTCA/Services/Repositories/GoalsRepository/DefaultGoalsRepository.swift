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
    
    func setNewGoal(for workoutType: WorkoutType,
                    _ movement: String,
                    date: Date,
                    value: String,
                    unit: String
    ) async throws {
        let context = backgroundContext
        
        try await context.perform {
            do {
                print("🔹 setNewGoal: Start")
                
                let user = try self.fetchUser(in: context)
                print("✅ User fetched: \(user.id)")
                
                let goals = self.fetchOrCreateGoals(for: user, in: context)
                print("✅ Goals entity ready for user: \(user.id)")
                
                let newGoal = self.createGoalEntity(
                    workoutType: workoutType,
                    movement: movement,
                    date: date,
                    value: value,
                    unit: unit,
                    in: context
                )
                print("✅ New Goal Created: \(newGoal.workoutType)  - \(newGoal.movement ?? "N/A")")
                
                self.addGoal(newGoal, to: goals)
                print("✅ Goal added to GoalsEntity")
                
                try self.saveData(context: context)
            } catch {
                print("❌ Error in setNewGoal: \(error)")
                throw error
            }
        }
    }
    
    
    // MARK: - Methods
    
    private func fetchUser(in context: NSManagedObjectContext) throws -> UserEntity {
        print("🔹 fetchUser: Attempting to fetch user")
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        guard let user = try context.fetch(fetchRequest).first else {
            print("❌ No user found in database")
            throw NSError(domain: "WorkoutError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ No user found in database."])
        }
        print("✅ User found: \(user.id)")
        return user
    }
    
    /// Fetching or Creating GoalsEntity
    private func fetchOrCreateGoals(for user: UserEntity, in context: NSManagedObjectContext) -> GoalsEntity {
        if let existingGoals = user.goals {
            print("✅ Existing GoalsEntity found for user: \(user.id)")
            return existingGoals
        } else {
            print("🔹 No GoalsEntity found, creating new one for user: \(user.id)")
            let newGoals = GoalsEntity(context: context)
            user.goals = newGoals
            return newGoals
        }
    }
    
    /// creating GoalWorkoutEntity
    private func createGoalEntity(workoutType: WorkoutType, movement: String, date: Date, value: String, unit: String, in context: NSManagedObjectContext) -> GoalWorkoutEntity {
        print("🔹 Creating new GoalWorkoutEntity")
        let goal = GoalWorkoutEntity(context: context)
        goal.id = UUID().uuidString
        goal.workoutType = workoutType.rawValue
        goal.movement = movement
        goal.date = date
        goal.value = Double(value) ?? 0.0 
        print("✅ Goal created: \(goal.workoutType) - \(goal.movement ?? "N/A")")
        return goal
    }
    
    ///Adding Goal to GoalsEntity
    private func addGoal(_ goal: GoalWorkoutEntity, to goals: GoalsEntity) {
        print("🔹 addGoal: Attempting to add goal to GoalsEntity")
        
        if goals.goalsWorkout == nil {
            print("🔸 workoutGoals is nil, initializing as an empty array.")
            goals.goalsWorkout = []
        } else {
            print("🔸 workoutGoals is already initialized: \(goals.goalsWorkout?.count ?? 0) items")
        }
        
        goals.goalsWorkout?.insert(goal)  // Dodanie celu do workoutGoals
        print("✅ Goal added: \(goal.workoutType) - \(goal.movement ?? "N/A")")
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
            print("✅ Core Data zapisane, wysyłam event")
            try context.save()
            print("💾 Changes saved in Core Data")
        } catch {
            print("❌ Błąd przy zapisywaniu danych: \(error)")
            throw error
        }
    }
    
}
