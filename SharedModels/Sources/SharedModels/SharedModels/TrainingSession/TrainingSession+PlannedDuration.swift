//
//  TrainingSession+PlannedDuration.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

extension TrainingSession {

    /// Class length in minutes: warm-up, every block's time cap, cool-down.
    public var plannedTotalMinutes: Int {
        (warmUp?.time ?? 0)
            + workouts.reduce(0) { total, workout in total + (workout.timeCap ?? 0) }
            + (coolDown?.time ?? 0)
    }
}
