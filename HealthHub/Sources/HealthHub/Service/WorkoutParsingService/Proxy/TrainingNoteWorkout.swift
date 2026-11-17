//
//  TrainingNoteWorkout.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// One planned workout, reduced to the names the cue is written from.
///
/// Names only, never prose: the proxy owns the shape of the prompt, so a request
/// cannot be rewritten into something the shared key should not answer.
public struct TrainingNoteWorkout: Encodable, Equatable, Sendable {

    /// Name of the workout as the plan carries it.
    public let name: String

    /// Workout type, e.g. `crossTraining`.
    public let type: String

    /// Display names of the exercises, in plan order.
    public let exercises: [String]

    public init(name: String, type: String, exercises: [String]) {
        self.name = name
        self.type = type
        self.exercises = exercises
    }
}
