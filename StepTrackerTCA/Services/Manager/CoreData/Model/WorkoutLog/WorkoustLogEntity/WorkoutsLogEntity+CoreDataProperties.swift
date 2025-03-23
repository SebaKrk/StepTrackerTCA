//
//  WorkoutsLogEntity+CoreDataProperties.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/03/2025.
//

import CoreData
import Foundation

extension WorkoutsLogEntity {
    
    /// A unique identifier for the workout log.
    @NSManaged public var id: String
    
    /// A set of strength workouts associated with this workout log.
    @NSManaged public var workoutStrength: Set<WorkoutStrengthEntity>?
    
    /// A set of weightlifting workouts linked to this workout log.
    @NSManaged public var workoutWeightlifting: Set<WorkoutWeightliftingEntity>?
    
    /// A set of fitness workouts recorded in this workout log.
    @NSManaged public var workoutFitness: Set<WorkoutFitnessEntity>?
    
    /// A set of CrossFit workouts associated with this workout log.
    @NSManaged public var workoutCross: Set<WorkoutCrossEntity>?
    
    /// A set of Hero workouts included in this workout log.
    @NSManaged public var workoutHero: Set<WorkoutHeroEntity>?
    
    // MARK: - Relations
    
    /// The user associated with this workout log.
    @NSManaged public var user: UserEntity?
    
}
