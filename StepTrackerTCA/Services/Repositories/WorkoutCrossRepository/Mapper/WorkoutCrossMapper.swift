//
//  WorkoutCrossMapper.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

struct WorkoutCrossMapper {
    static func mapEntity(from workout: WorkoutCrossEntity) -> WorkoutCross {
        WorkoutCross(
            id: workout.id,
            movement: workout.movement,
            date: workout.date,
            value: workout.value
        )
    }
    
}
