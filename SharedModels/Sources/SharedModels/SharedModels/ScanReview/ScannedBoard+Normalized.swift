//
//  ScannedBoard+Normalized.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

extension ScannedBoard {

    /// Fixes the two things the reader writes twice, before the board becomes a plan.
    ///
    /// Returns the cleaned board and, per workout section index, the kinds that were fixed.
    public func normalized() -> (board: ScannedBoard, fixes: [(sectionIndex: Int, kind: ScanFindingKind)]) {
        var fixes: [(sectionIndex: Int, kind: ScanFindingKind)] = []
        var seenNames: [String: Int] = [:]
        var workoutIndex = 0
        let sections = self.sections.map { section -> ScannedSection in
            guard section.kind != .warmup, section.kind != .cooldown else { return section }
            defer { workoutIndex += 1 }
            var roundCount = section.roundCount
            if !section.repScheme.isEmpty, roundCount > 0 {
                roundCount = 0
                fixes.append((workoutIndex, .ladderAndRoundsBothSet))
            }
            var name = section.name
            let key = name.lowercased()
            if !name.isEmpty {
                let count = (seenNames[key] ?? 0) + 1
                seenNames[key] = count
                if count > 1 {
                    name = "\(name) \(count)"
                    fixes.append((workoutIndex, .duplicateBlockName))
                }
            }
            return ScannedSection(
                label: section.label,
                kind: section.kind,
                name: name,
                format: section.format,
                timeCapMin: section.timeCapMin,
                everySec: section.everySec,
                workSec: section.workSec,
                restSec: section.restSec,
                roundCount: roundCount,
                repScheme: section.repScheme,
                restBetweenRoundsSec: section.restBetweenRoundsSec,
                writtenDurationMin: section.writtenDurationMin,
                text: section.text,
                notes: section.notes,
                uncertain: section.uncertain,
                movements: section.movements
            )
        }
        let board = ScannedBoard(
            boardKind: boardKind,
            title: title,
            activity: activity,
            classTimeCapMin: classTimeCapMin,
            sections: sections
        )
        return (board, fixes)
    }
}
