//
//  GoalWorkoutEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/03/2025.
//

import CoreData
import Foundation

extension GoalWorkoutEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalWorkoutEntity> {
        return NSFetchRequest<GoalWorkoutEntity>(entityName: "GoalWorkoutEntity")
    }
    
    ///
    @NSManaged public var id: String
    
    /// Enum: "weightlifting", "strength", "fitness", "cross", "hero"
    @NSManaged public var workoutType: String
    
    /// Enum: e.g. "cleanAndJerk", "snatch" (only for weightlifting)
    @NSManaged public var movement: String?
    
    ///
    @NSManaged public var date: Date
    
    /// Weight (kg/lbs) for weightlifting, Time (seconds) for fitness/hero
    @NSManaged public var value: Double
    
    ///
    @NSManaged public var goals: GoalsEntity?
}

extension GoalWorkoutEntity: Identifiable {}
