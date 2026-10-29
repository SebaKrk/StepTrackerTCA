//
//  ScanReviewValidator.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Checks a scanned plan before it is saved.
///
/// Two kinds of findings: `boardFindings` come from what the board said and cannot be
/// re-derived later (doubts, defaults, fixes); `planFindings` are rules on the plan
/// itself and are recomputed after every edit, so they close on their own.
public enum ScanReviewValidator {

    /// Loads above this are read errors, not programming.
    public static let maxPlausibleKilograms = 300

    /// Hard stops: nothing to save.
    public static func hardFindings(board: ScannedBoard, plan: TrainingSession) -> [ScanFinding] {
        guard board.boardKind != .notAWorkout, !plan.workouts.isEmpty else {
            return [ScanFinding(kind: .emptyPlan, blockId: nil, blockName: plan.title)]
        }
        return plan.workouts
            .filter { $0.exercises.isEmpty }
            .map { ScanFinding(kind: .emptyBlock, blockId: $0.id, blockName: $0.name) }
    }

    /// Doubts and defaults from the board, mapped onto the plan's blocks by position.
    public static func boardFindings(
        board: ScannedBoard,
        fixes: [(sectionIndex: Int, kind: ScanFindingKind)],
        plan: TrainingSession
    ) -> [ScanFinding] {
        var findings: [ScanFinding] = []
        for (index, section) in board.workoutSections.enumerated() {
            guard plan.workouts.indices.contains(index) else { continue }
            let block = plan.workouts[index]
            for fix in fixes where fix.sectionIndex == index {
                findings.append(ScanFinding(kind: fix.kind, blockId: block.id, blockName: block.name))
            }
            if section.timeCapMin == 0, block.type.isTimerRequired, let cap = block.timeCap {
                findings.append(ScanFinding(kind: .defaultTimeCapApplied(minutes: cap), blockId: block.id, blockName: block.name))
            }
            for field in section.uncertain {
                findings.append(ScanFinding(kind: .uncertainField(field: field), blockId: block.id, blockName: block.name))
            }
        }
        return findings
    }

    /// Rules on the plan; run again after each edit.
    public static func planFindings(_ plan: TrainingSession) -> [ScanFinding] {
        var findings: [ScanFinding] = []
        for block in plan.workouts {
            if block.type == .forTime, block.timeCap == nil {
                findings.append(ScanFinding(kind: .forTimeWithoutCap, blockId: block.id, blockName: block.name))
            }
            if block.type == .emom, let cap = block.timeCap, let every = block.everySeconds, every > 0,
               (cap * 60) % every != 0 {
                findings.append(ScanFinding(kind: .emomCapNotMultiple(everySeconds: every), blockId: block.id, blockName: block.name))
            }
            for exercise in block.exercises {
                let finding = { (kind: ScanFindingKind) in
                    ScanFinding(kind: kind, blockId: block.id, exerciseId: exercise.id, blockName: block.name, exerciseName: exercise.displayName)
                }
                if exercise.type == .unknown {
                    findings.append(finding(.unknownMovement(rawName: exercise.customName ?? "")))
                }
                if let weight = exercise.weight {
                    let heaviest = max(weight.men ?? 0, weight.women ?? 0)
                    if heaviest > maxPlausibleKilograms {
                        findings.append(finding(.loadTooHeavy(kilograms: heaviest)))
                    } else if let men = weight.men, let women = weight.women, women > men {
                        findings.append(finding(.womenHeavierThanMen))
                    }
                }
                let heaviestSet = exercise.plannedSets?.compactMap(\.suggestedWeight).max() ?? 0
                if Int(heaviestSet) > maxPlausibleKilograms, exercise.weight == nil {
                    findings.append(finding(.loadTooHeavy(kilograms: Int(heaviestSet))))
                }
            }
        }
        return findings
    }
}
