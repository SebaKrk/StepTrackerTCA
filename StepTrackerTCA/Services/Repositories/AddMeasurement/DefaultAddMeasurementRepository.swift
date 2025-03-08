//
//  DefaultAddMeasurementRepository.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 03/03/2025.
//
import Factory
import Foundation
import CoreData

final class DefaultAddMeasurementRepository: AddMeasurementRepository {
    
    // MARK: - Dependencies
    
    @LazyInjected(\.coreDataManger) private var coreDataManger
    
    // MARK: - Properties
    
    private var backgroundContext: NSManagedObjectContext {
        coreDataManger.backgroundContext
    }
    
    // MARK: - API
    
    func saveMeasurement(
        date: Date,
        workoutType: WorkoutType,
        movement: any MovementType,
        value: String,
        weightUnit: WeightUnit
    ) async throws {
        let context = backgroundContext
        
        try await context.perform {
            do {
                let user = try self.fetchUser(in: context)
                
                let workoutsLog = self.fetchWorkoutsLog(for: user) ?? self.createWorkoutsLog(for: user, in: context)
                
                let newRecord = DefaultWorkoutLogFactory.createEntity(for: workoutType, in: context)
                newRecord.id = UUID().uuidString
                newRecord.date = date
                newRecord.workoutType = workoutType.rawValue
                newRecord.movement = movement.rawValue
                newRecord.value = value
                newRecord.workouts = workoutsLog
                
                try self.saveData(context: context)
                
                print("""
                ✅ Workout saved successfully:
                - Date: \(date)
                - Workout Type: \(workoutType.rawValue)
                - Movement: \(movement.title)
                - Value: \(value) \(weightUnit.rawValue)
                """)
            } catch {
                print("❌ Error saveMeasurement \(workoutType.rawValue) workout: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchUser(in context: NSManagedObjectContext) throws -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        guard let user = try context.fetch(fetchRequest).first else {
            throw NSError(domain: "WorkoutError", code: 404, userInfo: [NSLocalizedDescriptionKey: "❌ No user found in database."])
        }
        return user
    }
    
    private func fetchWorkoutsLog(for user: UserEntity) -> WorkoutsLogEntity? {
        return user.workouts?.first
    }
    
    private func createWorkoutsLog(for user: UserEntity, in context: NSManagedObjectContext) -> WorkoutsLogEntity {
        let workoutsLog = WorkoutsLogEntity(context: context)
        workoutsLog.id = UUID().uuidString
        workoutsLog.user = user
        user.workouts = [workoutsLog]
        return workoutsLog
    }
    
    // MARK: - Core Data Helpers
    
    private func saveData(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
}
