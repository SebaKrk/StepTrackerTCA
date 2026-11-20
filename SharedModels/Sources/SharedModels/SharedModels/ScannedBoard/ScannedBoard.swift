//
//  ScannedBoard.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Schema v2 of a scanned board: what the model returns under structured outputs.
///
/// Every field is required and enums are closed, so the decoder never meets a
/// missing key and the mapper never guesses a block type from free text.
public struct ScannedBoard: Codable, Sendable, Equatable {
    /// What the model saw on the photo.
    public let boardKind: ScannedBoardKind

    /// Short workout title; the board's own heading when it has one.
    public let title: String

    /// Raw value of `WorkoutActivityType`; the mapper falls back to cross training.
    public let activity: String

    /// Top-line class budget ("TC: 60'"); informational, never a block cap. 0 = none.
    public let classTimeCapMin: Double

    /// Every block in board order.
    public let sections: [ScannedSection]

    public init(
        boardKind: ScannedBoardKind,
        title: String,
        activity: String,
        classTimeCapMin: Double = 0,
        sections: [ScannedSection]
    ) {
        self.boardKind = boardKind
        self.title = title
        self.activity = activity
        self.classTimeCapMin = classTimeCapMin
        self.sections = sections
    }

    /// Newest board form this build reads; the proxy shapes its reply for the form the caller names.
    ///
    /// Form 2 added `runBeforeEachMeters`: a caller on form 1 gets the run written out before each station instead.
    /// Form 3 added `repSchemeContinues`: a caller below it gets an open ladder as a note.
    public static let formVersion = 3

    /// Blocks that become workouts; warm-up / cool-down text is not a workout.
    public var workoutSections: [ScannedSection] {
        sections.filter { $0.kind != .warmup && $0.kind != .cooldown }
    }
}
