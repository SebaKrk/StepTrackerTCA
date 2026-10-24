//
//  BoardScore+WodScoreResult.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

extension BoardScore {

    /// Leaderboard form of a score entered after the workout.
    public init(_ result: WodScoreResult) {
        switch result {
        case .forTime(let time):
            self = .forTime(seconds: Int(time.rounded()))
        case .timeCap(let capSeconds, let remainingReps):
            self = .capped(capSeconds: capSeconds, remainingReps: remainingReps)
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
