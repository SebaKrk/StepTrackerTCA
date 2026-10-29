//
//  WorkoutSessionDraft.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 21/02/2026.
//

import Foundation

/// Mutable draft used by `WorkoutSessionEditorFeature` to create or edit a `WorkoutSessionNew`.
public struct WorkoutSessionDraft: Equatable, Sendable {

    public var name: String
    public var type: ExerciseWorkoutType
    public var timeCap: Int?
    public var rounds: Int?
    public var exercises: [ExerciseSession]
    /// Work/rest round timer draft (`.intervals` type only).
    public var interval: IntervalPlan?
    /// Minutes the block takes in the class; `nil` falls back to the time cap.
    public var plannedMinutes: Int?
    public var notes: String?
    public var everySeconds: Int?

    public init(
        name: String = "",
        type: ExerciseWorkoutType = .amrap,
        timeCap: Int? = 15,
        rounds: Int? = nil,
        exercises: [ExerciseSession] = [],
        interval: IntervalPlan? = nil,
        plannedMinutes: Int? = nil,
        notes: String? = nil,
        everySeconds: Int? = nil
    ) {
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
        self.interval = interval
        self.plannedMinutes = plannedMinutes
        self.notes = notes
        self.everySeconds = everySeconds
    }

    public init(workout: WorkoutSessionNew) {
        self.name = workout.name
        self.type = workout.type
        self.timeCap = workout.timeCap
        self.rounds = workout.rounds
        self.exercises = workout.exercises
        self.interval = workout.interval
        self.plannedMinutes = workout.plannedMinutes
        self.notes = workout.notes
        self.everySeconds = workout.everySeconds
    }
}
