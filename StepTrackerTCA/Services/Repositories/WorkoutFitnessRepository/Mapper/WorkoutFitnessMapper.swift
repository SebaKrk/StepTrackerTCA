//
//  WorkoutFitnessMapper.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

struct WorkoutFitnessMapper {
    static func mapEntity(from workout: WorkoutFitnessEntity) -> WorkoutFitness {
        WorkoutFitness(
            id: workout.id,
            movement: workout.movement,
            date: workout.date,
            value: workout.value
        )
    }
    
}
