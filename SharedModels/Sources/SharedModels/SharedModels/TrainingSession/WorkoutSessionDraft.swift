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

    public init(
        name: String = "",
        type: ExerciseWorkoutType = .amrap,
        timeCap: Int? = 15,
        rounds: Int? = nil,
        exercises: [ExerciseSession] = []
    ) {
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
    }

    public init(workout: WorkoutSessionNew) {
        self.name = workout.name
        self.type = workout.type
        self.timeCap = workout.timeCap
        self.rounds = workout.rounds
        self.exercises = workout.exercises
    }
}
