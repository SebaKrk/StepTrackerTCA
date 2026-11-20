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

    // MARK: - Fitness run

    /// Three stations behind a 1000 m run, built the way the results builder writes them:
    /// the whole run first, then one row per station.
    private static func fitnessRunState() -> WODScoringFeature.State {
        let run = ExerciseTarget.meters(3000)
        let ski = ExerciseTarget.meters(1000)
        let sled = ExerciseTarget.meters(50)
        let wallBalls = ExerciseTarget.reps(100)
        return WODScoringFeature.State(
            wodIndex: 0,
            result: WorkoutSessionResult(
                name: "WOD 1",
                description: "",
                exercises: [
                    ExerciseLogInput(
                        exerciseType: .running, target: run,
                        plannedReps: run.compactString, actualReps: run.compactString
                    ),
                    ExerciseLogInput(
                        exerciseType: .skiErg, target: ski,
                        plannedReps: ski.compactString, actualReps: ski.compactString
                    ),
                    ExerciseLogInput(
                        exerciseType: .sledPush, target: sled,
                        plannedReps: sled.compactString, plannedWeight: 152,
                        actualWeight: 152, actualReps: sled.compactString
                    ),
                    ExerciseLogInput(
                        exerciseType: .wallBalls, target: wallBalls,
                        plannedReps: wallBalls.compactString, plannedWeight: 6,
                        actualWeight: 6, actualReps: wallBalls.compactString
                    ),
                ]
            ),
            wodType: .forTime,
            fitnessRun: FitnessRunPlan(runMeters: 1000)
        )
    }

    private static func fitnessRunStore() -> TestStoreOf<WODScoringFeature> {
        let store = TestStore(initialState: fitnessRunState()) { WODScoringFeature() }
        store.exhaustivity = .off
        return store
    }

    @Test("A fitness run offers the choice even without a cap")
    func fitnessRunOffersTheSegmentWithoutACap() {
        #expect(Self.fitnessRunState().statusKind == .segment(.completed))
        #expect(Self.state(wodType: .forTime).statusKind == nil)
    }

    @Test("A fitness run counts its stations and never offers all of them as unfinished")
    func fitnessRunCountsStations() async {
        let store = Self.fitnessRunStore()
        #expect(store.state.runRowIndex == 0)
        #expect(store.state.stationCount == 3)

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(99)))
        #expect(store.state.dnfRounds == 2)
    }

    /// Counting from zero would empty every row on the flip, typed values included.
    @Test("The flip to unfinished starts one station short and keeps what was typed")
    func flipStartsOneStationShort() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.updateExerciseWeight(exerciseIndex: 2, text: "130")))
        await store.send(.view(.setStatus(.notFinished)))

        let rows = store.state.result.exercises
        #expect(store.state.dnfRounds == 2)
        #expect(store.state.interruptedExerciseIndex == 3)
        #expect(rows[2].actualWeight == 130)
        #expect(rows[3].actualReps == nil)
        #expect(rows[0].actualReps == ExerciseTarget.meters(2000).compactString)
    }

    @Test("Stopping short empties the stations never reached and counts the runs done")
    func unfinishedFitnessRunRedrawsTheList() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(1)))

        let rows = store.state.result.exercises
        #expect(store.state.interruptedExerciseIndex == 2)
        #expect(rows[0].actualReps == ExerciseTarget.meters(1000).compactString)
        #expect(rows[1].actualReps == rows[1].plannedReps)
        #expect(rows[2].actualReps == nil)
        #expect(rows[2].actualWeight == nil)
        #expect(rows[3].actualReps == nil)
    }

    @Test("Work on the interrupted station is stored in its own unit and earns its run")
    func partialStationKeepsItsUnit() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(1)))
        await store.send(.view(.updateExtraReps(20)))

        let rows = store.state.result.exercises
        #expect(rows[2].actualReps == ExerciseTarget.meters(20).compactString)
        #expect(rows[2].actualWeight == 152)
        #expect(rows[0].actualReps == ExerciseTarget.meters(2000).compactString)
        #expect(rows[3].actualReps == nil)
    }

    @Test("Moving the counter takes the partial work with the station it belonged to")
    func movingTheCounterDropsThePartial() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(1)))
        await store.send(.view(.updateExtraReps(20)))
        await store.send(.view(.updateRounds(2)))

        let rows = store.state.result.exercises
        #expect(store.state.dnfExtraReps == 0)
        #expect(rows[2].actualReps == rows[2].plannedReps)
        #expect(rows[2].actualWeight == 152)
        #expect(store.state.interruptedExerciseIndex == 3)
        #expect(rows[3].actualReps == nil)
        #expect(rows[0].actualReps == ExerciseTarget.meters(2000).compactString)
    }

    @Test("Back to completed restores the plan and keeps what the athlete typed")
    func completedRestoresTheList() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.updateExerciseWeight(exerciseIndex: 2, text: "130")))
        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(2)))
        await store.send(.view(.setStatus(.completed)))

        let rows = store.state.result.exercises
        #expect(store.state.interruptedExerciseIndex == nil)
        #expect(rows[0].actualReps == ExerciseTarget.meters(3000).compactString)
        #expect(rows[2].actualWeight == 130)
        #expect(rows[3].actualReps == rows[3].plannedReps)
        #expect(rows[3].actualWeight == 6)
    }

    @Test("An unfinished fitness run scores stations plus the partial work")
    func unfinishedFitnessRunScore() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(1)))
        await store.send(.view(.updateExtraReps(20)))
        await store.send(.view(.doneTapped))

        #expect(store.state.result.scoreResult == .amrap(rounds: 1, extraReps: 20))
        #expect(store.state.isDNF)
        #expect(store.state.phase == .entered)
    }

    /// The stations are done once each; the flat-round arithmetic of a capped For Time
    /// would multiply their targets by the counter.
    @Test("A fitness run never multiplies a station by the counter")
    func fitnessRunDoesNotMultiplyStations() async {
        let store = Self.fitnessRunStore()

        await store.send(.view(.setStatus(.notFinished)))
        await store.send(.view(.updateRounds(2)))

        #expect(!store.state.roundDrivesReps)
        #expect(store.state.result.exercises[1].actualReps == ExerciseTarget.meters(1000).compactString)
    }
}
