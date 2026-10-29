//
//  ClaudeBoardMapper.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation
import SharedModels

/// Decodes a structured-output reply into a ``ScannedBoard``.
///
/// The schema is enforced server-side, so the only failures left are a cut-off
/// reply (`max_tokens`), a refusal, or an empty content list.
public struct ClaudeBoardMapper: Sendable {

    public init() {}

    public func map(_ response: ClaudeAPIResponse) throws -> ScannedBoard {
        if response.isTruncated { throw ClaudeAPIError.truncated }
        if response.isRefusal { throw ClaudeAPIError.refused }
        guard let text = response.firstText, let data = text.data(using: .utf8) else {
            throw ClaudeAPIError.emptyResponse
        }
        #if DEBUG
        print("🤖 [ClaudeBoardMapper] RAW AI RESPONSE:\n\(text)\n")
        #endif
        let board = try JSONDecoder().decode(ScannedBoard.self, from: data)
        #if DEBUG
        debugLog(board)
        #endif
        return board
    }

    #if DEBUG
    /// One line per block and movement — enough to see a merged WOD or a lost movement at a glance.
    private func debugLog(_ board: ScannedBoard) {
        print("📦 [ClaudeBoardMapper] \(board.boardKind.rawValue) \"\(board.title)\" activity=\(board.activity) classTC=\(board.classTimeCapMin) sections=\(board.sections.count)")
        for section in board.sections {
            var head = "  └─ \(section.kind.rawValue) \"\(section.name)\" format=\(section.format.rawValue)"
            if section.timeCapMin > 0 { head += " cap=\(section.timeCapMin)" }
            if section.roundCount > 0 { head += " rounds=\(section.roundCount)" }
            if !section.repScheme.isEmpty { head += " ladder=\(section.repScheme)" }
            if section.everySec > 0 { head += " every=\(section.everySec)s" }
            if !section.uncertain.isEmpty { head += " uncertain=\(section.uncertain)" }
            print(head)
            for movement in section.movements {
                var line = "       ├─ \(movement.name)"
                if movement.targetValue > 0 { line += " \(movement.targetValue) \(movement.targetUnit.rawValue)" }
                if !movement.sets.isEmpty { line += " sets=\(movement.sets.map { $0.maxEffort ? "max" : "\(Int($0.value))" })" }
                if !movement.loads.isEmpty { line += " loads=\(movement.loads.map { "\($0.tier.rawValue) \($0.men)/\($0.women)" })" }
                if movement.perSide { line += " per side" }
                if movement.segment != .round { line += " \(movement.segment.rawValue)" }
                print(line)
            }
        }
    }
    #endif
}
