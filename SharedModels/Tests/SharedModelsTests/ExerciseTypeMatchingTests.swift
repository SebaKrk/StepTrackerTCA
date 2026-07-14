//
//  ExerciseTypeMatchingTests.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 12/07/2026.
//

import Foundation
import Testing
@testable import SharedModels

@Suite("ExerciseType catalog matching")
struct ExerciseTypeMatchingTests {

    /// Golden list: every raw OCR/AI name harvested from real field data that
    /// used to fall into the `.unknown` bucket, with the case it must resolve
    /// to after the catalog v2 extension. Guards both the new aliases and the
    /// new cases — a regression here silently re-poisons analytics.
    static let fieldDataGolden: [(rawName: String, expected: ExerciseType)] = [
        // Existing cases — alias gaps
        ("bar-facing burpees", .burpeeOverBar),
        ("hang squat clean", .hangClean),
        ("hang clean squat", .hangClean),
        ("power cleans", .powerClean),
        ("barbell lunges", .lunges),
        ("barbell bench press", .benchPress),
        ("barbell floor press", .floorPress),
        ("dumbbell devil press", .devilPress),
        ("single leg plank", .plank),
        ("box jumps over", .boxJumps),
        ("alternating pistols", .pistolSquats),
        ("seated overhead press", .shoulderPress),
        ("tricep push-ups", .pushUps),
        ("sumo deadlift", .deadlift),
        // New cases — catalog v2
        ("wall walk", .wallWalks),
        ("v-ups", .vUps),
        ("crossbody v-ups", .vUps),
        ("alternating single leg v-ups", .vUps),
        ("chest to bar pull-ups", .chestToBarPullUps),
        ("GHD sit-ups", .ghdSitUps),
        ("box step-ups", .boxStepUps),
        ("box step over", .boxStepOvers),
        ("russian twist", .russianTwist),
        ("L-sit", .lSit),
        ("one leg glute bridge", .gluteBridge),
        ("handstand shoulder taps", .handstandShoulderTaps),
        ("overhead carry", .overheadCarry),
        ("bear hug carries", .bearHugCarry),
        ("triceps plate extension", .tricepsExtension),
        ("plate raise", .plateRaise),
        ("landmine anti-rotation", .landmineAntiRotation),
        ("shoulder to overhead", .shoulderToOverhead),
    ]

    @Test("Every field-data raw name resolves to its catalog case", arguments: fieldDataGolden)
    func fieldDataResolves(entry: (rawName: String, expected: ExerciseType)) {
        #expect(ExerciseType.matched(fromRawName: entry.rawName) == entry.expected)
    }

    @Test("Matching is case-insensitive and trims whitespace")
    func normalization() {
        #expect(ExerciseType.matched(fromRawName: "  BAR-FACING BURPEES  ") == .burpeeOverBar)
        #expect(ExerciseType.matched(fromRawName: "ghd SIT-UPS") == .ghdSitUps)
    }

    @Test("Distance-based suffix heuristics still apply")
    func distanceHeuristics() {
        #expect(ExerciseType.matched(fromRawName: "1,600-meter run") == .running)
        #expect(ExerciseType.matched(fromRawName: "500m row") == .rowing)
        #expect(ExerciseType.matched(fromRawName: "2 km bike") == .cycling)
    }

    @Test("Unrecognized names still fall back to .unknown")
    func unknownFallback() {
        #expect(ExerciseType.matched(fromRawName: "flux capacitor swings") == .unknown)
        #expect(ExerciseType.matched(fromRawName: "") == .unknown)
    }
}
