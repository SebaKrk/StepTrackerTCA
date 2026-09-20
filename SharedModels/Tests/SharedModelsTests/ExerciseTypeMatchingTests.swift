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
        // Catalog v6 — first TestFlight harvest (unrecognized-names radar)
        ("barbell bicep curls", .bicepCurl),
        ("dumbbell curls", .bicepCurl),
        ("single arm swing", .kettlebellSwing),
        ("medicine ball slam", .ballSlam),
        ("slam ball", .ballSlam),
        ("kettlebell deadlift", .kettlebellDeadlift),
        ("KB deadlift", .kettlebellDeadlift),
        ("split jerk", .splitJerk),
        ("medicine ball squats", .medicineBallSquat),
        ("box dips", .dips),
        ("bench dips", .dips),
        ("medicine ball box step-ups", .medicineBallBoxStepUps),
        ("dumbbell overhead extension", .tricepsExtension),
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

    // MARK: - Implement dimension (catalog v7)

    @Test("A whole-name match wins before any implement token is stripped")
    func equipmentStrippingIsFallbackOnly() {
        // Movements that carry the implement in their identity must keep resolving
        // exactly as before — stripping first would send them to .unknown.
        #expect(ExerciseType.resolve(rawName: "kettlebell swing").type == .kettlebellSwing)
        #expect(ExerciseType.resolve(rawName: "kettlebell swing").equipment == nil)
        #expect(ExerciseType.resolve(rawName: "dumbbell snatch").type == .dumbbellSnatch)
        #expect(ExerciseType.resolve(rawName: "dumbbell snatch").equipment == nil)
    }

    @Test("An implement stated in the name is lifted out of it")
    func equipmentIsDetected() {
        let goblet = ExerciseType.resolve(rawName: "kettlebell goblet squats")
        #expect(goblet.type == .gobletSquat)
        #expect(goblet.equipment == .kettlebell)

        let press = ExerciseType.resolve(rawName: "single dumbbell strict press")
        #expect(press.type == .shoulderPress)
        #expect(press.equipment == .dumbbell)
    }

    @Test("Two different implements in one name are too ambiguous to guess")
    func ambiguousEquipmentIsDropped() {
        #expect(ExerciseType.resolve(rawName: "db kb thruster").equipment == nil)
    }

    @Test("Dropping a trailing plural does not glue unrelated movements together")
    func singularisationEdgeCases() {
        #expect(ExerciseType.resolve(rawName: "dips").type == .dips)
        #expect(ExerciseType.resolve(rawName: "burpees").type == .burpees)
        #expect(ExerciseType.resolve(rawName: "strict press").type == .shoulderPress)
        #expect(ExerciseType.resolve(rawName: "turkish get up").type == .turkishGetUp)
    }

    @Test("Implement prefixes removed from the catalog still resolve, now with the implement")
    func implementPrefixesResolveThroughStripping() {
        let cases: [(String, ExerciseType, Equipment)] = [
            ("DB bench press", .benchPress, .dumbbell),
            ("barbell bench press", .benchPress, .barbell),
            ("dumbbell curls", .bicepCurl, .dumbbell),
            ("barbell bicep curls", .bicepCurl, .barbell),
            ("DB floor press", .floorPress, .dumbbell),
            ("BB hang cleans", .hangClean, .barbell),
            ("barbell lunges", .lunges, .barbell),
            ("DB lunges", .lunges, .dumbbell),
            ("barbell push jerks", .pushJerk, .barbell),
            ("BB push press", .pushPress, .barbell),
            ("DB shoulder press", .shoulderPress, .dumbbell),
            ("barbell split jerk", .splitJerk, .barbell),
            ("BB clean", .squatClean, .barbell),
            ("DB thruster", .thrusters, .dumbbell),
            ("DB overhead extension", .tricepsExtension, .dumbbell),
            ("dumbbell goblet squat", .gobletSquat, .dumbbell),
            ("KB goblet squat", .gobletSquat, .kettlebell),
        ]
        for (rawName, expectedType, expectedEquipment) in cases {
            let resolved = ExerciseType.resolve(rawName: rawName)
            #expect(resolved.type == expectedType, "\(rawName) resolved to \(resolved.type)")
            #expect(resolved.equipment == expectedEquipment, "\(rawName) implement was \(String(describing: resolved.equipment))")
        }
    }

    @Test("Aliases that must keep their implement still resolve to the movement")
    func implementKeptWhereStrippingWouldMisfire() {
        // "barbell row" minus the implement is "row" — the rower, not a bent-over row.
        #expect(ExerciseType.resolve(rawName: "barbell row").type == .bentOverRow)
        #expect(ExerciseType.resolve(rawName: "BB row").type == .bentOverRow)
        #expect(ExerciseType.resolve(rawName: "burpee over barbell").type == .burpeeOverBar)
    }

    @Test("Every unrecognized name from the app 0.7 harvest resolves under catalog v7")
    func fieldDataV7() {
        let cases: [(String, ExerciseType, Equipment?)] = [
            ("turkish get up", .turkishGetUp, nil),
            ("kettlebell goblet squats", .gobletSquat, .kettlebell),
            ("single dumbbell strict press", .shoulderPress, .dumbbell),
            ("snatch balance", .snatchBalance, nil),
            ("good morning", .goodMorning, nil),
            ("burpee pull-ups", .burpeePullUps, nil),
            ("burpee over the DB", .burpeeOverDumbbell, nil),
            ("one arm plank", .plank, nil),
            ("overhead reverse lunges", .lunges, nil),
            ("strict handstand push-ups", .handstandPushUps, nil),
        ]
        for (rawName, expectedType, expectedEquipment) in cases {
            let resolved = ExerciseType.resolve(rawName: rawName)
            #expect(resolved.type == expectedType, "\(rawName) resolved to \(resolved.type)")
            #expect(resolved.equipment == expectedEquipment, "\(rawName) implement was \(String(describing: resolved.equipment))")
        }
    }

    @Test("New v7 movements carry the implement they are normally done with")
    func v7DefaultEquipment() {
        #expect(ExerciseType.snatchBalance.defaultEquipment == .barbell)
        #expect(ExerciseType.goodMorning.defaultEquipment == .barbell)
        // The dumbbell is cleared, not lifted — so it carries no implement,
        // exactly like .burpeeOverBar.
        #expect(ExerciseType.burpeeOverDumbbell.defaultEquipment == nil)
        #expect(ExerciseType.burpeeOverBar.defaultEquipment == nil)
        #expect(ExerciseType.burpeePullUps.defaultEquipment == nil)
    }

    @Test("Catalog version is bumped so the re-match job replays old unknowns")
    func catalogVersionBumped() {
        #expect(ExerciseType.catalogVersion >= 7)
    }

    @Test("The burpee family resolves each variant to its own movement")
    func burpeeFamily() {
        #expect(ExerciseType.resolve(rawName: "burpees").type == .burpees)
        #expect(ExerciseType.resolve(rawName: "burpee box jumps").type == .burpeeBoxJumps)
        #expect(ExerciseType.resolve(rawName: "burpee broad jump").type == .burpeeBroadJump)
        #expect(ExerciseType.resolve(rawName: "burpees to target").type == .burpeeToTarget)
        #expect(ExerciseType.resolve(rawName: "burpee pull-ups").type == .burpeePullUps)
    }

    @Test("Clearing an object is scored apart from landing on it")
    func burpeeBoxJumpOverIsItsOwnMovement() {
        #expect(ExerciseType.resolve(rawName: "burpee box jump over").type == .burpeeBoxJumpOvers)
        #expect(ExerciseType.resolve(rawName: "burpee over box").type == .burpeeBoxJumpOvers)
        #expect(ExerciseType.resolve(rawName: "burpee box jump").type == .burpeeBoxJumps)
    }

    @Test("Lateral variants land on the object they clear")
    func lateralBurpeeVariants() {
        #expect(ExerciseType.resolve(rawName: "lateral burpee over bar").type == .burpeeOverBar)
        #expect(ExerciseType.resolve(rawName: "lateral bar-facing burpee").type == .burpeeOverBar)
        #expect(ExerciseType.resolve(rawName: "lateral burpee over dumbbell").type == .burpeeOverDumbbell)
        #expect(ExerciseType.resolve(rawName: "db facing burpees").type == .burpeeOverDumbbell)
        #expect(ExerciseType.resolve(rawName: "lateral burpee over box").type == .burpeeBoxJumpOvers)
    }

    @Test("The object jumped over is never mistaken for the implement lifted")
    func jumpedOverObjectIsNotAnImplement() {
        #expect(ExerciseType.resolve(rawName: "burpee over the DB").equipment == nil)
        #expect(ExerciseType.resolve(rawName: "burpee over barbell").equipment == nil)
    }
}
