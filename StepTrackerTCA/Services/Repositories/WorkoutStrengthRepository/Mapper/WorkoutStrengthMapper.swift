//
//  WorkoutStrengthMapper.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/03/2025.
//

import Foundation

struct WorkoutStrengthMapper {
    static func mapEntity(from workout: WorkoutStrengthEntity) -> WorkoutStrength {
        WorkoutStrength(
            id: workout.id,
            movement: workout.movement,
            date: workout.date,
            value: workout.value
        )
    }
    
}
