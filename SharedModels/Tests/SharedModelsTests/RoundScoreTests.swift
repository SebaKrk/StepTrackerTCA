//
//  RoundScoreTests.swift
//  SharedModelsTests
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Testing

@testable import SharedModels

/// Pins how a partial round is split between movements. A scoreboard counts it in
/// board order: the athlete owes the earlier movements their full round before the
/// next one scores at all.
@Suite("Round score")
struct RoundScoreTests {

    /// 9 pull-ups then 10 thrusters — the example the type's own documentation uses.
    private static let sizes = [9, 10]

    @Test("Whole rounds alone give each movement its size times the count")
    func wholeRoundsOnly() {
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 0, completedRounds: 2, extraReps: 0) == 18)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 2, extraReps: 0) == 20)
    }

    @Test("A partial round fills the earlier movement first")
    func partialRoundFillsInBoardOrder() {
        // 14 extra reps = 9 pull-ups (the whole movement) + 5 thrusters.
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 0, completedRounds: 2, extraReps: 14) == 27)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 2, extraReps: 14) == 25)
    }

    @Test("A later movement scores nothing until the earlier one is paid off")
    func laterMovementWaitsItsTurn() {
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 2, extraReps: 9) == 20)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 2, extraReps: 10) == 21)
    }

    @Test("Extra reps past a whole round never overflow into another one")
    func extraRepsClampToOneRound() {
        // 25 extras exceed a 19-rep round; both movements cap at one more round.
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 0, completedRounds: 2, extraReps: 25) == 27)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 2, extraReps: 25) == 30)
    }

    @Test("Extras before the first full round still score")
    func extrasWithoutAnyWholeRound() {
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 0, completedRounds: 0, extraReps: 5) == 5)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 1, completedRounds: 0, extraReps: 5) == 0)
    }

    @Test("Nonsense input scores zero rather than trapping")
    func guardsAgainstNonsense() {
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 7, completedRounds: 2, extraReps: 0) == 0)
        #expect(RoundScore.reps(roundSizes: Self.sizes, movementIndex: 0, completedRounds: -1, extraReps: 0) == 0)
        #expect(RoundScore.reps(roundSizes: [], movementIndex: 0, completedRounds: 2, extraReps: 0) == 0)
    }

    /// The IOS-00177 invariant: what a movement scores is its whole-block total, so
    /// the round count is already inside the number and must never be applied again.
    @Test("A movement's score is the block total, not one round's worth")
    func scoreIsAlreadyTheBlockTotal() {
        let total = RoundScore.reps(roundSizes: [20], movementIndex: 0, completedRounds: 4, extraReps: 0)
        #expect(total == 80)
        // Multiplying by the round count a second time is the bug this pins against.
        #expect(total != 20)
    }
}
