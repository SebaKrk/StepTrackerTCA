//
//  WorkoutHeroWodMapper.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/04/2025.
//

import Foundation

struct WorkoutHeroWodMapper {
    static func mapEntity(from workout: WorkoutHeroEntity) -> WorkoutHeroWod {
        WorkoutHeroWod(
            id: workout.id,
            movement: workout.movement,
            date: workout.date,
            value: workout.value
        )
    }
    
}
