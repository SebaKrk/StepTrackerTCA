//
//  BoardScoreKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 27/10/2026.
//

import Foundation

/// What a block's leaderboard result measures.
public enum BoardScoreKind: Sendable, Equatable {

    /// Finish time, or the reps left at the cap.
    case time

    /// Rounds and extra reps.
    case rounds

    /// Reps summed over every interval (EMOM, Tabata).
    case totalReps

    /// Heaviest load lifted.
    case load

    /// No comparable result.
    case none

    /// The block can put a result on the leaderboard.
    public var isScored: Bool {
        self != .none
    }
}
