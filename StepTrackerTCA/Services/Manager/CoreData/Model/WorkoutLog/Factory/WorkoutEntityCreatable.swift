//
//  WorkoutEntityCreatable.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/03/2025.
//

import Foundation
import CoreData

protocol WorkoutLogFactory {
    static func createEntity(for type: WorkoutType, in context: NSManagedObjectContext) -> WorkoutEntityProtocol
}
