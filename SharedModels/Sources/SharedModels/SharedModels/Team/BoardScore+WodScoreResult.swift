//
//  BoardScore+WodScoreResult.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

extension BoardScore {

    /// Leaderboard form of a score entered after the workout.
    ///
    /// The result card stores a For Time attempt that hit the cap as rounds + reps (`.amrap`);
    /// read without the block type it would outrank every finisher, so the block type decides.
    public init(_ result: WodScoreResult, blockType: ExerciseWorkoutType, timeCapMinutes: Int?) {
        let capSeconds = (timeCapMinutes ?? 0) * 60
        switch result {
        case .forTime(let time):
            self = .forTime(seconds: Int(time.rounded()))
        case .timeCap(let capSeconds, let remainingReps):
            self = .capped(capSeconds: capSeconds, remainingReps: remainingReps)
        case .amrap(let rounds, let extraReps) where blockType == .forTime:
            self = .cappedRounds(capSeconds: capSeconds, rounds: rounds, extraReps: extraReps)
        case .amrap(let rounds, let extraReps):
            self = .amrap(rounds: rounds, extraReps: extraReps)
        case .forLoad(let weight):
            self = .load(kilograms: weight)
        case .forReps(let reps):
            self = .reps(reps)
        case .completed, .custom:
            self = .unranked
        }
    }
}
