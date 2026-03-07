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
/// immutable even if the source plan is later edited (e.g. weight changed from 40kg to 80kg).
public struct WorkoutSessionResult: Equatable, Codable, Sendable {

    // MARK: - Properties

    /// WOD name, e.g. "WOD 1" or a custom name from the plan.
    public var name: String

    /// Snapshot of the workout content at the time of execution,
    /// e.g. "21-15-9 Thrusters 43kg + Pull-ups".
    public var description: String

    /// Free-form result entered by the user, e.g. "14:32", "12+5 rnd", "80kg".
    public var score: String
    
    /// Optional note for this WOD.
    public var note: String

    // MARK: - Init

    public init(
        name: String,
        description: String,
        score: String = "",
        note: String = ""
    ) {
        self.name = name
        self.description = description
        self.score = score
        self.note = note
    }
}
