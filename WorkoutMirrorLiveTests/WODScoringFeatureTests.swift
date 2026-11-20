//
//  WODScoringFeatureTests.swift
//  WorkoutMirrorLiveTests
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import Testing

@testable import WorkoutMirrorLive

/// Pins the two rules a result card cannot express in its types: which status the
/// header carries, and what "Done" turns each kind of entry into. Both are matrices
/// an edit can shift silently, because every branch keeps compiling either way.
@MainActor
struct WODScoringFeatureTests {

    // MARK: - Fixtures

    private static func state(
        wodType: ExerciseWorkoutType,
        scoreResult: WodScoreResult = .completed,
        exercises: [ExerciseLogInput] = [],
        capMinutes: Int? = nil,
        isReadOnly: Bool = false,
        wasScored: Bool = false
    ) -> WODScoringFeature.State {
        WODScoringFeature.State(
            wodIndex: 0,
            result: WorkoutSessionResult(
                name: "WOD 1",
                description: "",
                scoreResult: scoreResult,
                exercises: exercises
            ),
            wodType: wodType,
            capMinutes: capMinutes,
            isReadOnly: isReadOnly,
            wasScored: wasScored
        )
    }

    // MARK: - Status

    /// The invariant that no type can enforce: `wodStatus` and `isDNF` are two
    /// sources of truth about the same fact, so a card could claim a WOD was
    /// completed while its own score says the cap cut it short.
    @Test("A card that did not finish never shows the completed pill")
    func unfinishedNeverReadsAsCompleted() {
        let card = Self.state(
            wodType: .forTime,
            scoreResult: .amrap(rounds: 3, extraReps: 49),
            capMinutes: 12,
            isReadOnly: true,
            wasScored: true
        )

        #expect(card.isDNF)
        #expect(card.statusKind != .pill(.completed))
        #expect(card.statusKind == .pill(.notFinished))
    }

    @Test("A capped For Time offers the choice while it is still editable")
    func cappedForTimeOffersTheSegment() {
        let card = Self.state(wodType: .forTime, capMinutes: 12)
        #expect(card.statusKind == .segment(.completed))
    }

    @Test("Formats that carry no verdict show no control at all")
    func formatsWithoutAVerdict() {
        for wodType in [ExerciseWorkoutType.strength, .olympicWeightlifting, .amrap, .intervals] {
            #expect(Self.state(wodType: wodType, wasScored: true).statusKind == nil, "\(wodType)")
        }
    }

    @Test("An untouched card shows no verdict until something is entered")
    func emptyCardShowsNoVerdict() {
        #expect(Self.state(wodType: .emom).statusKind == nil)
        #expect(Self.state(wodType: .emom, wasScored: true).statusKind == .pill(.completed))
    }

    // MARK: - Done

    @Test("Lifting scores the heaviest load across the block")
    func liftingScoresTheHeaviestLoad() async {
        let store = TestStore(
            initialState: Self.state(
                wodType: .strength,
                exercises: [
                    ExerciseLogInput(sets: [SetEntry(reps: 5, weight: 100), SetEntry(reps: 3, weight: 120)])
                ]
            )
        ) {
            WODScoringFeature()
        }

        await store.send(.view(.doneTapped)) {
            $0.result.scoreResult = .forLoad(weight: 120)
            $0.phase = .entered
        }
    }

    @Test("A timed block scores the clock")
    func timedBlockScoresTheClock() async {
        var initial = Self.state(wodType: .forTime, capMinutes: 12)
        initial.draftMinutes = 9
        initial.draftSeconds = 30

        let store = TestStore(initialState: initial) { WODScoringFeature() }

        await store.send(.view(.doneTapped)) {
            $0.result.scoreResult = .forTime(time: 570)
            $0.phase = .entered
        }
    }

    @Test("An AMRAP scores rounds plus loose reps")
    func amrapScoresRoundsAndReps() async {
        var initial = Self.state(wodType: .amrap, capMinutes: 20)
        initial.dnfRounds = 5
        initial.dnfExtraReps = 3

        let store = TestStore(initialState: initial) { WODScoringFeature() }

        await store.send(.view(.doneTapped)) {
            $0.result.scoreResult = .amrap(rounds: 5, extraReps: 3)
            $0.phase = .entered
        }
    }

    /// The headline is the sum of the per-movement fields, whatever unit each
    /// field was stored in — the team board ranks both formats by total reps.
    @Test("EMOM and Tabata score the sum of the movement totals")
    func totalPerMovementSumsTheFields() async {
        let store = TestStore(
            initialState: Self.state(
                wodType: .emom,
                exercises: [
                    ExerciseLogInput(target: .reps(10), actualReps: "54x"),
                    ExerciseLogInput(target: .calories(20), actualReps: "20 cal"),
                ]
            )
        ) {
            WODScoringFeature()
        }

        await store.send(.view(.doneTapped)) {
            $0.result.scoreResult = .forReps(reps: 74)
            $0.phase = .entered
        }
    }

    @Test("Mobility carries no load and no clock — done means done")
    func confirmationJustCompletes() async {
        let store = TestStore(initialState: Self.state(wodType: .mobility)) {
            WODScoringFeature()
        }

        await store.send(.view(.doneTapped)) {
            $0.phase = .entered
        }
    }

    // MARK: - Read-only

    /// The gate lives at the entrance of the reducer rather than in each case, so
    /// this pins that a card built read-only ignores everything the view could send.
    @Test("A read-only card ignores every action the view can send")
    func readOnlyCardIgnoresEverything() async {
        let store = TestStore(
            initialState: Self.state(wodType: .forTime, capMinutes: 12, isReadOnly: true, wasScored: true)
        ) {
            WODScoringFeature()
        }

        await store.send(.view(.startEditingTapped))
        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.addNoteTapped))
        await store.send(.view(.updateRounds(4)))
    }
}
