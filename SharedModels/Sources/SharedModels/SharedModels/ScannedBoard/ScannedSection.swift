//
//  ScannedSection.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// One block of the board, in board order. Sentinels instead of optionals: 0, "" and [] mean "not on the board".
public struct ScannedSection: Codable, Sendable, Equatable {
    /// Marker as written: "A)", "B1-B3", "WOD 1"; "" when none.
    public let label: String

    /// Role of the block.
    public let kind: ScannedSectionKind

    /// What the athlete works on; "" lets the mapper name the block.
    public let name: String

    /// Timing format of the block; `none` for plain set work.
    public let format: ScannedSectionFormat

    /// Cap in minutes next to the format keyword; 0 when none.
    public let timeCapMin: Double

    /// EMOM cadence in seconds: 60, 120 for E2MOM; 0 otherwise.
    public let everySec: Int

    /// Work seconds of a tabata / intervals block; 0 otherwise.
    public let workSec: Int

    /// Rest seconds of a tabata / intervals block; 0 otherwise.
    public let restSec: Int

    /// Whole list repeats this many times; 0 when `repScheme` is used.
    public let roundCount: Int

    /// Ladder "21-15-9" → [21, 15, 9]; empty otherwise.
    public let repScheme: [Int]

    /// Rest between rounds in seconds; 0 when none.
    public let restBetweenRoundsSec: Int

    /// Minutes written next to the block ("| 12,5 min"); 0 when none.
    public let writtenDurationMin: Double

    /// Board text of a warm-up / cool-down block; "" for other kinds.
    public let text: String

    /// Anything else written about the block; "" when nothing.
    public let notes: String

    /// Field paths the model could not read with confidence ("timeCapMin").
    public let uncertain: [String]

    /// Movements in board order; empty for warm-up / cool-down text.
    public let movements: [ScannedMovement]

    public init(
        label: String = "",
        kind: ScannedSectionKind,
        name: String = "",
        format: ScannedSectionFormat = .none,
        timeCapMin: Double = 0,
        everySec: Int = 0,
        workSec: Int = 0,
        restSec: Int = 0,
        roundCount: Int = 0,
        repScheme: [Int] = [],
        restBetweenRoundsSec: Int = 0,
        writtenDurationMin: Double = 0,
        text: String = "",
        notes: String = "",
        uncertain: [String] = [],
        movements: [ScannedMovement] = []
    ) {
        self.label = label
        self.kind = kind
        self.name = name
        self.format = format
        self.timeCapMin = timeCapMin
        self.everySec = everySec
        self.workSec = workSec
        self.restSec = restSec
        self.roundCount = roundCount
        self.repScheme = repScheme
        self.restBetweenRoundsSec = restBetweenRoundsSec
        self.writtenDurationMin = writtenDurationMin
        self.text = text
        self.notes = notes
        self.uncertain = uncertain
        self.movements = movements
    }
}
