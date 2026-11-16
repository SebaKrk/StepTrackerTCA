//
//  ExerciseTargetNotationTests.swift
//  SharedModelsTests
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Testing

@testable import SharedModels

/// Pins the notation a result field is stored in. `compactString` writes it,
/// `EnteredValue` reads it, and `stored(entered:)` writes what a field edit produced —
/// three places that have to agree, and one documented place where two of them do not.
@Suite("Exercise target notation")
struct ExerciseTargetNotationTests {

    @Test(
        "A typed number round-trips through the unit it was planned in",
        arguments: [
            (ExerciseTarget.reps(5), "12", "12x"),
            (.calories(5), "20", "20 cal"),
            (.meters(5), "400", "400m"),
            (.seconds(5), "30", "30s"),
            (.minutes(5), "2", "2 min"),
        ]
    )
    func storedCarriesTheUnit(target: ExerciseTarget, typed: String, expected: String) {
        #expect(target.stored(entered: typed) == expected)
        // What `stored` writes is what `compactString` would have written.
        #expect(target.with(count: Int(typed) ?? 0).compactString == expected)
    }

    /// The one asymmetry, pinned on purpose: an editor field shows no suffix for
    /// rounds or laps, so a typed value stores bare while the plan's own notation
    /// spells the unit out. Aligning them would change what gets saved.
    @Test("Rounds and laps store bare although their plan notation does not")
    func roundsAndLapsAreDeliberatelyAsymmetric() {
        #expect(ExerciseTarget.rounds(4).stored(entered: "4") == "4")
        #expect(ExerciseTarget.rounds(4).compactString == "4 rounds")

        #expect(ExerciseTarget.laps(4).stored(entered: "4") == "4")
        #expect(ExerciseTarget.laps(4).compactString == "4 laps")
    }

    @Test("An empty field stores nothing rather than a bare unit")
    func emptyInputStoresEmpty() {
        for target in [ExerciseTarget.reps(5), .calories(5), .meters(5), .rounds(5)] {
            #expect(target.stored(entered: "") == "")
        }
    }

    @Test("Scaling a target to the whole block keeps its unit")
    func withCountKeepsTheUnit() {
        #expect(ExerciseTarget.calories(20).with(count: 80).compactString == "80 cal")
        #expect(ExerciseTarget.meters(400).with(count: 1600).compactString == "1600m")
        #expect(ExerciseTarget.reps(10).with(count: 40).compactString == "40x")
    }

    @Test("Reading a stored value gives the number back, unit or not")
    func enteredValueReadsWhatWasStored() {
        #expect(EnteredValue.number("54x") == 54)
        #expect(EnteredValue.number("20 cal") == 20)
        #expect(EnteredValue.number("400m") == 400)
        #expect(EnteredValue.number("done") == nil)
    }

    /// A bare number reads as plain reps — which is why a bare-stored lap count
    /// would display as reps. The asymmetry above is what keeps that reachable.
    @Test("A bare number is indistinguishable from plain reps")
    func bareNumbersReadAsReps() {
        #expect(EnteredValue.isPlainReps("54"))
        #expect(EnteredValue.isPlainReps("54x"))
        #expect(!EnteredValue.isPlainReps("20 cal"))
    }
}
