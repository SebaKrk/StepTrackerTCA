//
//  ScoreEntryMatrixTests.swift
//  SharedModelsTests
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Testing

@testable import SharedModels

/// Pins the format matrix: what each workout type asks for, and what shape its
/// result takes. The compiler already forces a new type to answer these questions;
/// these tests force the existing answers to stay answered the same way.
@Suite("Score entry matrix")
struct ScoreEntryMatrixTests {

    @Test(
        "Each type asks for exactly one kind of score",
        arguments: [
            (ExerciseWorkoutType.forTime, ScoreEntryKind.time),
            (.amrap, .roundsAndReps),
            (.emom, .totalPerMovement),
            (.tabata, .totalPerMovement),
            (.strength, .sets),
            (.olympicWeightlifting, .sets),
            (.mobility, .confirmation),
            (.intervals, .confirmation),
        ]
    )
    func scoreEntryKindPerType(type: ExerciseWorkoutType, expected: ScoreEntryKind) {
        #expect(type.scoreEntryKind == expected)
    }

    @Test("Only lifting and mobility keep per-set rows")
    func keepsSetRowsPerType() {
        let keeping: Set<ExerciseWorkoutType> = [.strength, .olympicWeightlifting, .mobility]
        for type in ExerciseWorkoutType.allCases {
            #expect(type.keepsSetRows == keeping.contains(type), "\(type)")
        }
    }

    /// The IOS-00177 invariant in its prefill half: only a format whose plan states
    /// one round's work multiplies that work by the round count.
    @Test("Only For Time and EMOM multiply the planned target by rounds")
    func multipliesTargetByRoundsPerType() {
        let multiplying: Set<ExerciseWorkoutType> = [.forTime, .emom]
        for type in ExerciseWorkoutType.allCases {
            #expect(type.multipliesTargetByRounds == multiplying.contains(type), "\(type)")
        }
    }

    @Test("Mobility is the one format that records no load")
    func takesWeightPerType() {
        for type in ExerciseWorkoutType.allCases {
            #expect(type.takesWeight == (type != .mobility), "\(type)")
        }
    }

    @Test("Strength covers barbell work and nothing else")
    func isStrengthPerType() {
        let lifting: Set<ExerciseWorkoutType> = [.strength, .olympicWeightlifting]
        for type in ExerciseWorkoutType.allCases {
            #expect(type.isStrength == lifting.contains(type), "\(type)")
        }
    }

    /// `keepsSetRows` and `scoreEntryKind` answer two different questions and are
    /// allowed to disagree. Mobility is where they do — pinned so nobody "aligns" them.
    @Test("Mobility keeps rows although it only asks for confirmation")
    func mobilityDisagreesOnPurpose() {
        #expect(ExerciseWorkoutType.mobility.scoreEntryKind == .confirmation)
        #expect(ExerciseWorkoutType.mobility.keepsSetRows)
    }
}
