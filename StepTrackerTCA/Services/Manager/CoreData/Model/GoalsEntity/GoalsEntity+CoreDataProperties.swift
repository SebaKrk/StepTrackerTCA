//
//  GoalsEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/03/2025.
//

import CoreData
import Foundation

extension GoalsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalsEntity> {
        return NSFetchRequest<GoalsEntity>(entityName: "GoalsEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var goalWeight: GoalWeightEntity?
    @NSManaged public var workoutGoals: Set<GoalWorkoutEntity>?
    @NSManaged public var user: UserEntity?
}

extension GoalsEntity: Identifiable {}
