//
//  WorkoutSessionResult.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 03/03/2026.
//

import Foundation

/// Result of a single WOD within a completed planned workout.
///
/// Contains a **snapshot** of the workout description at the time of execution —
/// immutable even if the source plan is later edited.
public struct WorkoutSessionResult: Equatable, Codable, Sendable, Identifiable {

    // MARK: - Properties

    public var id: UUID

    /// WOD name, e.g. "WOD 1" or a custom name from the plan.
    public var name: String

    /// Snapshot of the workout content at the time of execution,
    /// e.g. "21-15-9 Thrusters 43kg + Pull-ups".
    public var description: String

    /// Typed WOD score — replaces free-form string.
    public var scoreResult: WodScoreResult

    /// Optional note for this WOD.
    public var note: String

    /// Per-exercise inputs collected on the Summary screen.
    public var exercises: [ExerciseLogInput]

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        scoreResult: WodScoreResult = .completed,
        note: String = "",
        exercises: [ExerciseLogInput] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.scoreResult = scoreResult
        self.note = note
        self.exercises = exercises
    }
}
