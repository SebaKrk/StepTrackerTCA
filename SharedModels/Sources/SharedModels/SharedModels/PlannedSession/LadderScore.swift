//
//  LadderScore.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 07/11/2026.
//

import Foundation

/// Reps one movement has completed when a rep-ladder WOD stops part-way.
///
/// The partial round is counted in board order across every movement, the way a
/// scoreboard counts it: in a round of 7 with three movements, 4 reps means four
/// of the first movement and none of the other two.
public enum LadderScore {

    /// Reps `movementIndex` has done after `completedRounds` whole rounds plus `extraReps` of the next.
    public static func reps(
        ladder: [Int],
        movementIndex: Int,
        completedRounds: Int,
        extraReps: Int
    ) -> Int {
        let whole = ladder.prefix(max(0, completedRounds)).reduce(0, +)
        guard completedRounds >= 0, completedRounds < ladder.count, movementIndex >= 0 else { return whole }
        let rung = ladder[completedRounds]
        let owedToEarlierMovements = movementIndex * rung
        return whole + min(max(extraReps - owedToEarlierMovements, 0), rung)
    }
}
