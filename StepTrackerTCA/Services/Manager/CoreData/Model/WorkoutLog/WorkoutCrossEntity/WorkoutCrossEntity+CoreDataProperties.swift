//
//  WorkoutCrossEntity.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 04/03/2025.
//

import CoreData
import Foundation

extension WorkoutCrossEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutCrossEntity> {
        return NSFetchRequest<WorkoutCrossEntity>(entityName: "WorkoutCrossEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var workoutType: String
    @NSManaged public var movement: String
    @NSManaged public var date: Date
    @NSManaged public var value: String
    
    // MARK: - Relations
    
    @NSManaged public var workouts: WorkoutsLogEntity?
    
}

