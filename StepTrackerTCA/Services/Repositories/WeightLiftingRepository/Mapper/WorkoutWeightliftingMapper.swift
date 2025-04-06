//
//  WorkoutWeightliftingMapper.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/03/2025.
//

import Foundation

struct WorkoutWeightliftingMapper {
    static func mapEntity(from workout: WorkoutWeightliftingEntity) -> WorkoutWeightlifting {
        WorkoutWeightlifting(
            id: workout.id,
            movement: workout.movement,
            date: workout.date,
            value: workout.value
        )
    }
}
