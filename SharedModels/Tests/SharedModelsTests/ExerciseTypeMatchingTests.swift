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
    /// to after each catalog extension (v2 field harvest, v3 mobility/rehab).
    /// Guards both the new aliases and the new cases — a regression here
    /// silently re-poisons analytics.
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
        // New cases — catalog v3 (mobility / rehab)
        ("cat-cow", .catCow),
        ("koci grzbiet", .catCow),
        ("bird dog", .birdDog),
        ("dead bug", .deadBug),
        ("martwy robak", .deadBug),
        ("child's pose", .childsPose),
        ("ukłon japoński", .childsPose),
        ("pelvic tilt knee to chest", .pelvicTilt),
        ("hamstring stretch", .hamstringStretch),
        ("figure four stretch", .gluteStretch),
        ("piriformis stretch", .gluteStretch),
        ("lying spinal twist", .spinalTwist),
        ("knee across body stretch", .spinalTwist),
        ("skręty tułowia", .spinalTwist),
        ("foam rolling", .foamRolling),
        ("rolowanie", .foamRolling),
        ("prone arm raises", .proneArmRaises),
        ("prone y raise", .proneArmRaises),
        ("open book stretch", .openBook),
        ("thread the needle", .threadTheNeedle),
        ("thoracic extension on foam roller", .thoracicExtension),
        ("mckenzie press-up", .cobraStretch),
        ("cobra", .cobraStretch),
        ("wall slides", .wallSlides),
        ("pigeon pose", .pigeonPose),
        ("hip flexor stretch", .couchStretch),
        ("couch stretch", .couchStretch),
        ("90/90 hip stretch", .ninetyNinety),
        ("world's greatest stretch", .worldsGreatestStretch),
        ("shoulder dislocates", .pvcPassThroughs),
        ("pvc pass-throughs", .pvcPassThroughs),
        ("downward facing dog", .downwardDog),
        // Catalog v4 — model paraphrases harvested from the first rehab scan
        ("pelvic tilt with knee to chest", .pelvicTilt),
        ("torso rotation stretch", .spinalTwist),
        ("figure 4 glute stretch", .gluteStretch),
        ("supine knee crossover stretch", .spinalTwist),
        // Catalog v5 — the plain (full) clean was missing entirely
        ("squat clean", .squatClean),
        ("clean", .squatClean),
        ("full clean", .squatClean),
        ("hang squat clean", .hangClean),
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
