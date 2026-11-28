//
//  SideNotesGeneration.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

/// What the warm-up or cool-down notes header offers for AI-written notes.
enum SideNotesGeneration: Equatable, Sendable {

    /// The AI button is shown.
    case available

    /// Notes are empty but the plan has no workouts yet — a hint replaces the button.
    case needsWorkouts

    /// Notes are written or being written — nothing is offered.
    case hidden
}
