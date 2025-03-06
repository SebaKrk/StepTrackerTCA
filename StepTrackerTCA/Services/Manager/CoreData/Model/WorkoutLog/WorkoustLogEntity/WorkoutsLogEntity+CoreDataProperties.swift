//
//  WorkoutsLogEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/03/2025.
//

import CoreData
import Foundation

extension WorkoutsLogEntity {
    @NSManaged public var id: String
    
    // MARK: - Relations
    
    @NSManaged public var user: UserEntity?
    
    /// powizanie z poszczegolnymi typow treningu
    @NSManaged public var workoutStrength: Set<WorkoutStrengthEntity>?
    @NSManaged public var workoutWeightlifting: Set<WorkoutWeightliftingEntity>?
    @NSManaged public var workoutFitness: Set<WorkoutFitnessEntity>?
    @NSManaged public var workoutCross: Set<WorkoutCrossEntity>?
    @NSManaged public var workoutHero: Set<WorkoutHeroEntity>?
}
