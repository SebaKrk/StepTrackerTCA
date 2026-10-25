//
//  TrainingSession+PlannedDuration.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

extension TrainingSession {

    /// Class length in minutes: warm-up, every block's planned time (or its time cap), cool-down.
    public var plannedTotalMinutes: Int {
        (warmUp?.time ?? 0)
            + workouts.reduce(0) { total, workout in total + (workout.plannedMinutes ?? workout.timeCap ?? 0) }
            + (coolDown?.time ?? 0)
    }

    /// Minutes still missing to reach `target`; zero when the plan is long enough.
    public func missingPlannedMinutes(target: Int = 60) -> Int {
        max(0, target - plannedTotalMinutes)
    }

    /// Blocks with neither a planned time nor a time cap — they add nothing to the class length.
    public var blocksWithoutPlannedTime: [WorkoutSessionNew.ID] {
        workouts.filter { $0.plannedMinutes == nil && $0.timeCap == nil }.map(\.id)
    }
}
