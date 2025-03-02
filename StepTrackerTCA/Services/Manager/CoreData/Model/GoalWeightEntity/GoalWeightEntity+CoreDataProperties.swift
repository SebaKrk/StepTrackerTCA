//
//  GoalWeightEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/02/2025.
//
//

import Foundation
import CoreData

extension GoalWeightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalWeightEntity> {
        return NSFetchRequest<GoalWeightEntity>(entityName: "GoalWeightEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var weight: Double
    @NSManaged public var weightUnit: String
    @NSManaged public var dateAdded: Date

}

extension GoalWeightEntity : Identifiable {

}
