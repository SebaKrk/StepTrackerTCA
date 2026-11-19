//
//  ProxyStrategy.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation
import SharedModels

/// Parses a scan through the server-side proxy.
///
/// The phone prepares the photo and reads the answer; the prompt, the schema and
/// the API key live in the function. The chosen ``WorkoutParsingBackend`` travels
/// with the request as a mode, so switching backends in settings still compares
/// the three prompts against each other.
public actor ProxyStrategy: WorkoutParsingStrategy {

    // MARK: - Properties

    /// Which prompt the proxy should build for this scan.
    private let backend: WorkoutParsingBackend

    /// Transport to the deployed functions.
    private let proxy: ScanProxyClient

    // MARK: - Initialization

    public init(backend: WorkoutParsingBackend, proxy: ScanProxyClient) {
        self.backend = backend
        self.proxy = proxy
    }

    // MARK: - WorkoutParsingStrategy

    public func parseWorkout(_ input: WorkoutScanInput) async throws -> ScannedBoard {
        guard backend.needsPhoto, let imageData = input.imageData else {
            return try await parseText(input.ocrText, model: input.model)
        }
        let jpeg = try ScanImageDownscaler.jpeg(from: imageData)
        let board = try await proxy.scanBoard(
            mode: backend.proxyMode,
            imageData: jpeg,
            ocrText: input.ocrText,
            language: ScanLanguage.preferredName(),
            model: input.model
        )
        logBoard(board)
        return board
    }

    public func parseWorkoutText(_ text: String) async throws -> ScannedBoard {
        try await parseText(text, model: nil)
    }

    /// The text path, with the model the caller asked for.
    ///
    /// `parseWorkoutText` comes from the protocol and carries only the transcript,
    /// so the overridden model travels through here instead.
    private func parseText(_ text: String, model: String?) async throws -> ScannedBoard {
        let board = try await proxy.scanBoard(
            mode: .text,
            imageData: nil,
            ocrText: text,
            language: ScanLanguage.preferredName(),
            model: model
        )
        logBoard(board)
        return board
    }

    // MARK: - Private

    #if DEBUG
    /// One line per block and movement — enough to see a merged WOD or a lost movement at a glance.
    private func logBoard(_ board: ScannedBoard) {
        print("📦 [ProxyStrategy] \(board.boardKind.rawValue) \"\(board.title)\" activity=\(board.activity) classTC=\(board.classTimeCapMin) sections=\(board.sections.count)")
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
    #else
    private func logBoard(_ board: ScannedBoard) {}
    #endif
}
