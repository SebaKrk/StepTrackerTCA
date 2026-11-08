//
//  RoundScore.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

/// Reps one movement has completed in a block whose every round holds the same work.
///
/// The partial round is counted in board order, the way a scoreboard counts it: a
/// round of 9 pull-ups then 10 thrusters, scored with 14 extra reps, means nine
/// pull-ups and five thrusters.
///
/// Kin to `LadderScore` but not reducible to it. A ladder's round changes size from
/// round to round and every movement shares that size; here the size holds across
/// rounds and differs between movements. One signature cannot carry both without
/// taking a closure, which costs more in reading than the duplication saves.
public enum RoundScore {

    /// Reps `movementIndex` has done after `completedRounds` whole rounds plus `extraReps` of the next.
    public static func reps(
        roundSizes: [Int],
        movementIndex: Int,
        completedRounds: Int,
        extraReps: Int
    ) -> Int {
        guard roundSizes.indices.contains(movementIndex), completedRounds >= 0 else { return 0 }
        let size = roundSizes[movementIndex]
        let whole = size * completedRounds
        let owedToEarlierMovements = roundSizes.prefix(movementIndex).reduce(0, +)
        return whole + min(max(extraReps - owedToEarlierMovements, 0), size)
    }
}
