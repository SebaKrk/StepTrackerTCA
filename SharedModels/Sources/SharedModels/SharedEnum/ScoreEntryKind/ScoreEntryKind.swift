//
//  ScoreEntryKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

/// What a result card asks the athlete for.
///
/// Formats differ in their question, not in their plumbing: one kind can serve
/// several workout types, and a card reads this instead of switching on the type
/// itself — which is how the same matrix came to be written out in ten places.
public enum ScoreEntryKind: Equatable, Sendable {

    /// Minutes and seconds — a block scored by how long it took.
    case time

    /// Completed rounds plus the reps of the one left unfinished.
    case roundsAndReps

    /// One total per movement; the headline score is their sum.
    case totalPerMovement

    /// A table of reps times weight; the headline score is the heaviest set.
    case sets

    /// Nothing to measure — done is the whole result.
    case confirmation
}
