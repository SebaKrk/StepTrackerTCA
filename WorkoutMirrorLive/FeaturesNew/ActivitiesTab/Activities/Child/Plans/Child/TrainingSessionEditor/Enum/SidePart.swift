//
//  SidePart.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import Foundation

/// One draggable part of the warm-up or cool-down in the plan editor.
enum SidePart: String, Equatable, Sendable {

    /// The warm-up block (e.g. a Tabata).
    case warmUpBlock

    /// The warm-up written notes.
    case warmUpNotes

    /// The cool-down block.
    case coolDownBlock

    /// The cool-down written notes.
    case coolDownNotes

    /// The other part of the same section — the only one this part can swap with.
    var partner: SidePart {
        switch self {
        case .warmUpBlock: .warmUpNotes
        case .warmUpNotes: .warmUpBlock
        case .coolDownBlock: .coolDownNotes
        case .coolDownNotes: .coolDownBlock
        }
    }

    /// A part may only swap with its partner in the same section — never with itself or the other section.
    func canSwap(with other: SidePart) -> Bool {
        partner == other
    }

    /// Whether this part belongs to the warm-up (otherwise the cool-down).
    var isWarmUp: Bool {
        self == .warmUpBlock || self == .warmUpNotes
    }

    /// Drag payload; `Data`, not `String`, so the notes' text view never takes it as typed text.
    var dragPayload: Data {
        Data((Self.payloadPrefix + rawValue).utf8)
    }

    /// Reads a part back from a dropped payload; `nil` for anything this editor didn't drag.
    init?(dragPayload: Data) {
        let text = String(decoding: dragPayload, as: UTF8.self)
        guard text.hasPrefix(Self.payloadPrefix) else { return nil }
        self.init(rawValue: String(text.dropFirst(Self.payloadPrefix.count)))
    }

    /// Namespace that keeps the payload from matching unrelated drags.
    private static let payloadPrefix = "trainingSessionEditor."
}
