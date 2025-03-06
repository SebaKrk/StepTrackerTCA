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
    
    // MARK: - Relations
    
    /// Powiązane cele wagowe
    @NSManaged public var goalWeight: GoalWeightEntity?
    
    /// Powiązane cele dla konkretnych ćwiczeń
    @NSManaged public var workoutGoals: Set<GoalWorkoutEntity>?
    
    /// Użytkownik, do którego należą cele
    @NSManaged public var user: UserEntity?
    
}

extension GoalsEntity: Identifiable {}
