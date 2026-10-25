//
//  TrainingSession+FillClassLength.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

extension TrainingSession {

    /// Copy whose blocks share the minutes missing to `target`; ids stay the same.
    ///
    /// Blocks without a planned time take the missing minutes (on top of their time cap);
    /// when every block already has one, all blocks share them. Returns `self` when nothing is missing.
    public func fillingClassLength(to target: Int = 60) -> TrainingSession {
        let missing = missingPlannedMinutes(target: target)
        guard missing > 0, !workouts.isEmpty else { return self }

        let unplannedIds = Set(workouts.filter { $0.plannedMinutes == nil }.map(\.id))
        let receivers = unplannedIds.isEmpty ? Set(workouts.map(\.id)) : unplannedIds
        let share = missing / receivers.count
        var remainder = missing % receivers.count

        let filled = workouts.map { workout -> WorkoutSessionNew in
            guard receivers.contains(workout.id) else { return workout }
            var draft = WorkoutSessionDraft(workout: workout)
            let extra = share + (remainder > 0 ? 1 : 0)
            remainder = max(0, remainder - 1)
            draft.plannedMinutes = (workout.plannedMinutes ?? workout.timeCap ?? 0) + extra
            return WorkoutSessionNew(id: workout.id, draft: draft)
        }
        return TrainingSession(
            id: id,
            date: date,
            title: title,
            activity: activity,
            location: location,
            warmUp: warmUp,
            workouts: filled,
            coolDown: coolDown,
            teamPlanId: teamPlanId
        )
    }

    /// Block a group leaderboard ranks by default: the first one that is not strength, weightlifting or mobility.
    public var defaultScoredBlockId: WorkoutSessionNew.ID? {
        let unscored: Set<ExerciseWorkoutType> = [.strength, .olympicWeightlifting, .mobility]
        return workouts.first { !unscored.contains($0.type) }?.id ?? workouts.first?.id
    }
}
