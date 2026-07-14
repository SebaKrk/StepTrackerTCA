//
//  TrainingSession+CatalogRematch.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 12/07/2026.
//

import Foundation

// MARK: - Catalog Re-match

/// One-time repair pass support: plans store the `ExerciseType` resolved at
/// scan time, so extending the catalog (new cases/aliases) does not fix
/// already-saved data by itself. These helpers rebuild the affected value tree
/// with `.unknown` entries re-resolved, preserving every identity (`id`) so
/// downstream references stay valid. All return `nil` when nothing changed,
/// letting callers skip database writes for untouched records.

extension ExerciseSession {

    /// Identity-preserving copy — the public initializers generate a fresh
    /// `id`, which would break references to the original exercise.
    fileprivate init(
        id: UUID,
        type: ExerciseType,
        customName: String?,
        target: ExerciseTarget?,
        weight: WeightConfiguration?,
        info: String?,
        plannedSets: [PlannedSet]?
    ) {
        self.id = id
        self.type = type
        self.customName = customName
        self.target = target
        self.weight = weight
        self.info = info
        self.plannedSets = plannedSets
    }

    /// Re-resolves an `.unknown` exercise against the current catalog.
    /// On success `customName` is cleared — by invariant it carries the raw
    /// OCR/AI name only while the type is `.unknown`.
    public func rematchedAgainstCatalog() -> ExerciseSession? {
        guard type == .unknown, let rawName = customName else { return nil }
        let resolved = ExerciseType.matched(fromRawName: rawName)
        guard resolved != .unknown else { return nil }
        return ExerciseSession(
            id: id,
            type: resolved,
            customName: nil,
            target: target,
            weight: weight,
            info: info,
            plannedSets: plannedSets
        )
    }
}

extension WorkoutSessionNew {

    /// Identity-preserving copy — see `ExerciseSession` note above.
    fileprivate init(
        id: UUID,
        name: String,
        type: ExerciseWorkoutType,
        timeCap: Int?,
        rounds: Int?,
        exercises: [ExerciseSession]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
    }

    /// Returns a copy with all `.unknown` exercises re-resolved.
    public func rematchedAgainstCatalog() -> WorkoutSessionNew? {
        var changed = false
        let rematchedExercises = exercises.map { exercise -> ExerciseSession in
            guard let rematched = exercise.rematchedAgainstCatalog() else { return exercise }
            changed = true
            return rematched
        }
        guard changed else { return nil }
        return WorkoutSessionNew(
            id: id,
            name: name,
            type: type,
            timeCap: timeCap,
            rounds: rounds,
            exercises: rematchedExercises
        )
    }
}

extension TrainingSession {

    /// Returns a copy with all `.unknown` exercises across all WODs re-resolved.
    /// Warm-up and cool-down carry no exercises, so only `workouts` is touched.
    public func rematchedAgainstCatalog() -> TrainingSession? {
        var changed = false
        let rematchedWorkouts = workouts.map { workout -> WorkoutSessionNew in
            guard let rematched = workout.rematchedAgainstCatalog() else { return workout }
            changed = true
            return rematched
        }
        guard changed else { return nil }
        return TrainingSession(
            id: id,
            date: date,
            title: title,
            activity: activity,
            location: location,
            warmUp: warmUp,
            workouts: rematchedWorkouts,
            coolDown: coolDown
        )
    }
}
