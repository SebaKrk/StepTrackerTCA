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
        print("✅ Saving measurement:")
        print("   Workout Type: \(workoutType.rawValue)")
        print("   Movement: \(movement.title)")
        print("   Value: \(value) \(weightUnit.rawValue)")
        print("   Date: \(date)")
    }
    
    // MARK: - Core Data Helpers
    
    private func saveData(context: NSManagedObjectContext) throws {
        try context.save()
    }
    
}
