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
    @NSManaged public var healthKitEnabled: Bool
    @NSManaged public var goals: GoalsEntity?
}

extension UserEntity: Identifiable {}
