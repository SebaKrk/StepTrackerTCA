//
//  CurrentWeightEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 24/02/2025.
//
//

import Foundation
import CoreData

extension CurrentWeightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CurrentWeightEntity> {
        return NSFetchRequest<CurrentWeightEntity>(entityName: "CurrentWeightEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var weight: Double
    @NSManaged public var dateAdded: Date

}

extension CurrentWeightEntity : Identifiable {

}
