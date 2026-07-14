//
//  TrainingSession+ImportCopy.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import Foundation

extension TrainingSession {

    /// Deep copy with brand-new identity at EVERY level — plan, workouts, exercises.
    ///
    /// On import the receiver's copy must not share any UUID with the sender's.
    /// Regenerating only the top-level `id` is not enough: nested
    /// `WorkoutSessionNew.id` / `ExerciseSession.id` would stay identical to the
    /// source, so per-workout/per-exercise state could bleed between two
    /// independent plans (or collide if the same plan is imported twice). This is
    /// the deliberate opposite of the identity-preserving copies in
    /// `TrainingSession+CatalogRematch` — the public inits used here mint fresh UUIDs.
    public func withNewIdentity(id: UUID, date: Date) -> TrainingSession {
        TrainingSession(
            id: id,
            date: date,
            title: title,
            activity: activity,
            location: location,
            warmUp: warmUp,
            workouts: workouts.map { workout in
                WorkoutSessionNew(
                    name: workout.name,
                    type: workout.type,
                    timeCap: workout.timeCap,
                    rounds: workout.rounds,
                    exercises: workout.exercises.map { exercise in
                        ExerciseSession(
                            type: exercise.type,
                            customName: exercise.customName,
                            target: exercise.target,
                            weight: exercise.weight,
                            info: exercise.info,
                            plannedSets: exercise.plannedSets
                        )
                    }
                )
            },
            coolDown: coolDown
        )
    }
}
