//
//  UserEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 02/03/2025.
//

import Foundation
import CoreData

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
    
    @NSManaged public var id: String
    @NSManaged public var email: String
    @NSManaged public var healthKitEnabled: Bool
    
    // MARK: - Relations
    
    @NSManaged public var goals: GoalsEntity?
    @NSManaged public var workouts: Set<WorkoutsLogEntity>?
}

extension UserEntity: Identifiable {}

