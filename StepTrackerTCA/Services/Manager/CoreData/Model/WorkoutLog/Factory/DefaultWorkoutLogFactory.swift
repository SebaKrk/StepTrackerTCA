//
//  DefaultWorkoutLogFactory.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/03/2025.
//

import CoreData
import Foundation

struct DefaultWorkoutLogFactory: WorkoutLogFactory {
    static func createEntity(for type: WorkoutType, in context: NSManagedObjectContext) -> WorkoutEntityProtocol {
        switch type {
        case .strength:
            return WorkoutStrengthEntity(context: context)
        case .weightlifting:
            return WorkoutWeightliftingEntity(context: context)
        case .fitness:
            return WorkoutFitnessEntity(context: context)
        case .cross:
            return WorkoutCrossEntity(context: context)
        case .hero:
            return WorkoutHeroEntity(context: context)
        }
    }
}
