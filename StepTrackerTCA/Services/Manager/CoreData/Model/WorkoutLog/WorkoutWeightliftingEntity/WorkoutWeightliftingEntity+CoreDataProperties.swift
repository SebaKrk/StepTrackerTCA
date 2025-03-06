//
//  WorkoutWeightliftingEntity.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 04/03/2025.
//

import CoreData
import Foundation

extension WorkoutWeightliftingEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutWeightliftingEntity> {
        return NSFetchRequest<WorkoutWeightliftingEntity>(entityName: "WorkoutWeightliftingEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var workoutType: String
    @NSManaged public var movement: String
    @NSManaged public var date: Date
    @NSManaged public var value: String
    
    // MARK: - Relations
    
    @NSManaged public var workouts: WorkoutsLogEntity?
    
}
