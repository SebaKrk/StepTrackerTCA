//
//  ExerciseWorkoutType+ScoreEntry.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

extension ExerciseWorkoutType {

    /// The one place that decides what a block of this type asks the athlete for.
    ///
    /// Mirrors `boardScoreKind` case for case today, by coincidence rather than by rule:
    /// one answers what the card asks, the other how the team board ranks. They may part.
    ///
    /// A capped For Time switches to rounds and reps once it is marked unfinished,
    /// which depends on the card's state rather than the type — the card resolves that.
    public var scoreEntryKind: ScoreEntryKind {
        switch self {
        case .forTime: .time
        case .amrap: .roundsAndReps
        case .emom, .tabata: .totalPerMovement
        case .strength, .olympicWeightlifting: .sets
        case .mobility, .intervals: .confirmation
        }
    }

    /// Lifting, where the result is a weight rather than a time or a rep count.
    public var isStrength: Bool {
        switch self {
        case .strength, .olympicWeightlifting: true
        case .forTime, .amrap, .emom, .tabata, .mobility, .intervals: false
        }
    }

    /// Whether movements of this type carry a load worth recording.
    public var takesWeight: Bool {
        switch self {
        case .forTime, .amrap, .emom, .tabata, .strength, .olympicWeightlifting, .intervals: true
        case .mobility: false
        }
    }

    /// Whether results of this type are built as per-set rows rather than one value per movement.
    ///
    /// Deliberately disagrees with `scoreEntryKind` for mobility: it confirms rather than
    /// scores, yet still keeps rows. Two independent questions, not one answered twice.
    public var keepsSetRows: Bool {
        switch self {
        case .strength, .olympicWeightlifting, .mobility: true
        case .forTime, .amrap, .emom, .tabata, .intervals: false
        }
    }

    /// Whether a movement's planned target counts one round, so the block's total is
    /// that target times the round count.
    ///
    /// Decides numbers that get saved, so it is a switch: a new format has to answer
    /// rather than inherit `false` and silently plan a fraction of the work.
    public var multipliesTargetByRounds: Bool {
        switch self {
        case .forTime, .emom: true
        case .amrap, .tabata, .strength, .olympicWeightlifting, .mobility, .intervals: false
        }
    }
}
